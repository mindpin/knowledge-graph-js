define (require, exports, module)->
  return KnowledgeNet

edge_equal = (e1, e2)->
  e1[0] == e2[0] and e1[1] == e2[1]

class KnowledgeNet
  constructor: (json_obj)->
    @_points_map = {}
    @_edges = []

    # 是否已清理多余边
    @cleaned = false

    for p in json_obj['points']
      @_points_map[p.id] =
        id: p.id
        name: p.name
        desc: p.desc
        edges: []
        parents: []
        children: []

    for e in json_obj['edges']
      parent_id = e['parent']
      child_id = e['child']

      @_edges.push [parent_id, child_id]

      parent = @find_by parent_id
      child = @find_by child_id

      parent['edges'].push [parent_id, child_id]
      parent['children'].push child_id

      child['edges'].push [parent_id, child_id]
      child['parents'].push parent_id


  find_by: (id)->
    @_points_map[id]


  points: ->
    @_points ?= (id for id of @_points_map)


  edges: ->
    @_edges


  roots: ->
    @_roots ?= (id for id of @_points_map when @is_root id)


  is_root: (id)->
    @find_by(id).parents.length is 0


  get_redundant_edges: ->
    _set = new DistanceSet(@)
    _arr = (id for id in @roots())

    # 宽度优先遍历
    while _arr.length > 0
      point = @find_by _arr.shift()
      _set.add point
      
      for child_id in point.children
        child = @find_by child_id
        _arr.push child_id if _set.is_parents_here child
          
    @deeps = _set.deeps

    return _set.redundant_edges


  clean_redundant_edges: ->
    unless @cleaned
      @clean_edge edge for edge in @get_redundant_edges()
      @cleaned = true

  # edge like ['A', 'B']
  clean_edge: (edge)->
    [parent_id, child_id] = edge
    parent = @find_by parent_id
    child  = @find_by child_id

    # 从父节点移除子，以及移除相应的边
    parent.children = parent.children.filter (id)->
      id isnt child_id

    parent.edges = parent.edges.filter (e)->
      not edge_equal(e, edge)

    # 从子节点移除父，以及移除相应的边
    child.parents = child.parents.filter (id)->
      id isnt parent_id

    child.edges = child.edges.filter (e)->
      not edge_equal(e, edge)

    # 移除边
    @_edges = @_edges.filter (e)->
      not edge_equal(e, edge)

  get_deeps: ->
    @clean_redundant_edges()
    @deeps

  get_tree_data: ->
    @clean_redundant_edges()

    arr = @__deeps_arr()

    # 添加边
    stack = []
    edges = []
    for id in arr
      point = @find_by id
      for pid in stack
        if pid in point.parents
          edges.push [pid, id]
          break
      stack.unshift id

    return {
      'points': arr
      'edges': edges
    }


  get_tree_nesting_data: ->
    @clean_redundant_edges()

    arr = @__deeps_arr()

    map = {}
    for id in arr
      point = @find_by id

      map[id] =
        id: point.id
        name: point.name
        desc: point.desc
        children: []
        deep: @deeps[id]

    stack = []
    for id in arr
      point = @find_by id

      for pid in stack
        if pid in point.parents
          map[pid].children.push map[id]
          break
      stack.unshift id

    re = for id in @roots()
      @__count map, id
      map[id]

    edges = for e in @edges()
      source = map[e[0]]
      target = map[e[1]]
      {
        "source": source
        "target": target
      }

    return {
      "roots": re.sort (a, b)-> b.count - a.count
      "edges": edges
    }


  __count: (map, pid)->
    map_point = map[pid]
    o_point = @find_by pid

    if not map_point.count
      map_point.count = 1
      for child_id in o_point.children
        map_point.count += @__count(map, child_id)

    map_point.count

  __deeps_arr: ->
    # deeps 排序数组
    ([@deeps[id], id] for id of @deeps)
      .sort (a, b)-> a[0] - b[0]
      .map (item)-> item[1]

  # 字符串分割，
  # <=6，不处理
  # 6< and <=12，均匀分成两段
  # 12< and <=18 均匀分成三段
  # 英文处理尚有 BUG，还需改进
  @break_text: (text)->
    # 第一步，拆分字符串，中文字符一个字是一个子串
    # 连续非中文字符不拆分
    arr = @__split(text)
    length = 0
    for x in arr
      length += x[1]
    
    # 第二步，计算子串长度
    slen = @__slen length

    # 第三步，分解子串
    re = []
    tmp = ['', 0]
    while arr.length > 0
      # console.log tmp, slen

      if tmp[1] >= slen
        # console.log "!"
        re.push tmp[0]
        tmp = ['', 0]

      x = arr.shift()
      tmp[0] += x[0]
      tmp[1] += x[1]

    re.push tmp[0]
    re


  @__split: (text)->
    arr = text.split ''
    re = []
    stack = ''

    push_stack = ->
      if stack.length > 0
        re.push [stack, Math.ceil(stack.length / 2)]
        stack = ''

    for s in arr
      if s.match /[\u4e00-\u9fa5]/
        push_stack()
        re.push [s, 1]
      else
        stack = stack + s

    push_stack()

    re

  @__slen: (length)->
    c = (length - 1) // 6
    Math.ceil(length / (c + 1))

# SET = {}
# RE = {}
# 宽度优先遍历节点
# 如果节点的父节点都在 SET 中
#   将节点置入 SET
#   处理 SET 中各个节点的路径长度信息
#   一旦发现冲突，解决冲突，并将导致冲突的边置入 RE

# 记录节点之间的路径长度
class DistanceSet
  constructor: (@net)->
    @set = {}
    @redundant_edges = []
    @deeps = {}

  is_parents_here: (point)->
    for parent_id in point.parents
      return false if !(parent_id of @set)
    return true

  add: (point)->
    @set[point.id] = {}
    deep = @_r(point, point, 1)
    @deeps[point.id] = deep

  _r: (current_point, point, distance)->
    deep = 1
    for parent_id in current_point.parents
      @_merge parent_id, point.id, distance
      d = @_r @net.find_by(parent_id), point, distance + 1
      deep = Math.max(deep, @deeps[parent_id] + 1)
    return deep

  _merge: (target_id, point_id, distance)->
    d0 = @set[target_id][point_id]

    if !d0
      @set[target_id][point_id] = distance
      return

    @set[target_id][point_id] = Math.max d0, distance

    if d0 != distance && Math.min(d0, distance) == 1
      @redundant_edges.push [target_id, point_id]

KnowledgeNet.DistanceSet = DistanceSet