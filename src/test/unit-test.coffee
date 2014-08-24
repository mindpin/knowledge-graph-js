###
  该用例来源于 2014.07.01 的一次导数据尝试
  cook-pan.graphml 转换为 json 时
  由于 graphml 文件数据有一些问题，其中存在自指向关联
  导致 json 中产生了 {"parent":"53b23f0f6c696e5c95070000","child":"53b23f0f6c696e5c95070000"}
  这样的数据。这样的数据会导致计算节点深度时遍历出错。
  目前 net.coffee 中已经修正了这个问题
###
FIXTURE_COOK_JSON_URL = 'fixture/cook-pan.json'

###
  该用例来源于 2014.8.24 的问题回报
  https://github.com/mindpin/knowledge-camp/issues/78
  此数据尝试加载时导致浏览器卡死
###
FIXTURE_COOK_ART_313_JSON_URL = 'fixture/art313.json'

JSON_LIST = [
  'fixture/g1.json'
  'fixture/g2.json'
  'fixture/g3.json'
  'fixture/g4.json'
  FIXTURE_COOK_JSON_URL
  FIXTURE_COOK_ART_313_JSON_URL
]

seajs.config
  base: '../../js/'
  paths:
    'graph': 'graph/dist'

seajs.use 'graph/net', (KnowledgeNet)->
  loaded = []
  length = JSON_LIST.length
  load_next = ->
    url = JSON_LIST.shift()
    jQuery.getJSON url, (obj)->
      loaded.push obj
      if loaded.length < length
        load_next()
      else
        [g1, g2, g3, g4, cook, art] = loaded
        do_test KnowledgeNet, g1, g2, g3, g4, cook, art

  load_next()


do_test = (KnowledgeNet, g1_obj, g2_obj, g3_obj, g4_obj, cook_obj, art_obj)->
  test 'JSON Object 检查', ->
    ok g1_obj['points'].length == 8
    ok g1_obj['edges'].length == 11

  # 数据，属性
  do ->
    knet = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet_cook = new KnowledgeNet(cook_obj)

    test '对象构建', ->
      ok knet.points().length == 8
      ok knet.edges().length == 11

    do ->
      n = knet.find_by('A')
      ne = knet.find_by('E')
      
      test '根据 ID 查找节点', ->
        equal n.id, 'A'
        equal n.name, 'A'

      test '节点关联的边-G1-A', ->
        edges = n.edges
        equal edges.length, 2 
        deepEqual edges.sort(), [['A', 'B'], ['A', 'C']]

      test '节点关联的边-G1-E', ->
        edges = ne.edges
        equal edges.length, 4
        deepEqual edges.sort(), [['B', 'E'], ['D', 'E'], ['E', 'G'], ['F', 'E']]

      test '子节点和父节点-G1-A', ->
        equal n.parents.length, 0
        equal n.children.length, 2
        deepEqual n.children.sort(), ['B', 'C']

      test '子节点和父节点-G1-E', ->
        equal ne.parents.length, 3
        deepEqual ne.parents.sort(), ['B', 'D', 'F']

        equal ne.children.length, 1
        deepEqual ne.children, ['G']

    test '查找根节点-G1', ->
      roots = knet.roots()
      equal roots.length, 1
      ok knet.is_root 'A'

    test '查找根节点-G2', ->
      roots = knet2.roots()
      equal roots.length, 3
      ok knet2.is_root 'I'
      ok knet2.is_root 'J'
      ok knet2.is_root 'O'
      ok !knet2.is_root 'P'

    test '查找根节点-COOK', ->
      roots = knet_cook.roots()
      equal roots.length, 1
      ok knet_cook.is_root '53b23f0f6c696e5c952d0000'

  # 多余边查找算法
  do ->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)
    knet4 = new KnowledgeNet(g4_obj)
    knet_cook = new KnowledgeNet(cook_obj)
    knet_art = new KnowledgeNet(art_obj)

    test '查找多余边-G1', ->
      redundant_edges = knet1.get_redundant_edges()
      deepEqual redundant_edges.sort(), [
        ['B', 'E'], ['D', 'H'], ['F', 'H']
      ]

    test '查找多余边-G2', ->
      redundant_edges = knet2.get_redundant_edges()
      deepEqual redundant_edges.sort(), []

    test '查找多余边-G3', ->
      redundant_edges = knet3.get_redundant_edges()
      deepEqual redundant_edges.sort(), [
        ['A', 'C'], ['A', 'D'], ['B', 'E'], ['C', 'F']
      ]

    test '查找多余边-G4', ->
      redundant_edges = knet4.get_redundant_edges()
      deepEqual redundant_edges.sort(), []

    test '查找多余边-COOK', ->
      redundant_edges = knet_cook.get_redundant_edges()
      deepEqual redundant_edges.sort(), []

    test '剔除多余边-G1', ->
      c = knet1.edges().length
      knet1.clean_redundant_edges()
      equal knet1.edges().length, c - 3 

      deepEqual knet1.find_by('B').children, ['D']
      deepEqual knet1.find_by('E').parents, ['D', 'F']

    test '剔除多余边-G2', ->
      c = knet2.edges().length
      knet2.clean_redundant_edges()
      equal knet2.edges().length, c 

    test '剔除多余边-G3', ->
      deepEqual knet3.find_by('C').edges, [
        ['A', 'C'],
        ['B', 'C'], 
        ['C', 'D'],
        ['C', 'F']
      ]

      c = knet3.edges().length
      knet3.clean_redundant_edges()
      equal knet3.edges().length, c - 4 

      deepEqual knet3.find_by('A').children, ['B']
      deepEqual knet3.find_by('A').edges, [['A', 'B']]

      deepEqual knet3.find_by('B').children, ['C']
      deepEqual knet3.find_by('B').edges, [['A', 'B'], ['B', 'C']]

      deepEqual knet3.find_by('C').children, ['D']
      deepEqual knet3.find_by('C').edges, [['B', 'C'], ['C', 'D']]

      deepEqual knet3.find_by('D').children, ['E']
      deepEqual knet3.find_by('E').children, ['F']

  # 最优化节点深度
  do ->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)
    knet4 = new KnowledgeNet(g4_obj)
    knet_cook = new KnowledgeNet(cook_obj)

    test 'g1 deeps', ->
      deepEqual knet1.get_deeps(), {
        'A':1, 
        'B':2, 'C':2
        'D':3, 'F':3
        'E':4
        'G':5
        'H':6
      }

    test 'g2 deeps', ->
      deepEqual knet2.get_deeps(), {
        'I':1, 'J':1 
        'K':2,
        'L':3, 'M':3
        'N':4

        'O':1
        'P':2
      }

    test 'g3 deeps', ->
      deepEqual knet3.get_deeps(), {
        'A':1, 'B':2, 'C':3, 'D':4, 'E':5, 'F':6
      }

    test 'g4 deeps', ->
      deepEqual knet4.get_deeps(), {
        'A':1, 
        'B':2, 'D':2
        'C':3, 
        'E':4, 
        'F':5
        'G':1
      }

    test 'cook deeps', ->
      console.log knet_cook
      window.knet = knet_cook
      deeps = knet_cook.get_deeps()
      equal Object.keys(deeps).length, 45


  # 生成树构建算法
  do ->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)
    knet4 = new KnowledgeNet(g4_obj)

    test 'g4 nodes count', ->
      equal knet4.points().length, 7

    test 'get g4 TREE', ->
      tree_data = knet4.get_tree_data()

      deepEqual tree_data['points'].sort(), ['A', 'B', 'C', 'D', 'E', 'F', 'G']
      deepEqual tree_data['edges'].sort(), [
        ['A', 'B'], ['A', 'D']
        ['B', 'C'], ['C', 'E']
        ['E', 'F'],
      ]

    test 'get g1 TREE', ->
      tree_data = knet1.get_tree_data()
      deepEqual tree_data['edges'].sort(), [
        ['A', 'B'], ['A', 'C']
        ['B', 'D'], ['C', 'F']
        ['E', 'G'], ['F', 'E'], # ['D', 'E'] // 生成方式不唯一
        ['G', 'H']
      ]

    test 'get g1 NEST TREE', ->
      tree_data = knet1.get_tree_nesting_data()
      deepEqual tree_data.roots[0].id, 'A'

  
  do ->
    test 'break-text', ->
      deepEqual KnowledgeNet.break_text('数组'), ['数组']
      deepEqual KnowledgeNet.break_text('创建数组'), ['创建数组']
      deepEqual KnowledgeNet.break_text('数组元素读写'), ['数组元素读写']

    test 'break-text', ->
      deepEqual KnowledgeNet.break_text('数组元素增删改'), [
        '数组元素', '增删改'
      ]
      deepEqual KnowledgeNet.break_text('对象属性的高级操作'), [
        '对象属性的', '高级操作'
      ]
      deepEqual KnowledgeNet.break_text('可读写性和可配置性的概念定义'), [
        '可读写性和', '可配置性的', '概念定义'
      ]

    test 'split', ->
      deepEqual KnowledgeNet.__split('不作死就不会死'), [
        ['不', 1],['作', 1],['死', 1]
        ['就', 1],['不', 1],['会', 1,], ['死', 1]
      ]

      deepEqual KnowledgeNet.__split('让我 go'), [
        ['让', 1],['我', 1],[' go', 2]
      ]

      deepEqual KnowledgeNet.__split('follow 你的心'), [
        ['follow ', 4],['你', 1],['的', 1], ['心', 1]
      ]

      deepEqual KnowledgeNet.__split('不 zuo 不 die 懂不懂 ?'), [
        ['不', 1],[' zuo ', 3],['不', 1], [' die ', 3]
        ['懂', 1],['不', 1],['懂', 1],[' ?', 1]
      ]

    test 'slen', ->
      equal KnowledgeNet.__slen(1), 1
      equal KnowledgeNet.__slen(2), 2
      equal KnowledgeNet.__slen(3), 3
      equal KnowledgeNet.__slen(4), 4
      equal KnowledgeNet.__slen(5), 5
      equal KnowledgeNet.__slen(6), 6
      equal KnowledgeNet.__slen(7), 4
      equal KnowledgeNet.__slen(8), 4
      equal KnowledgeNet.__slen(9), 5
      equal KnowledgeNet.__slen(10), 5
      equal KnowledgeNet.__slen(11), 6
      equal KnowledgeNet.__slen(12), 6
      equal KnowledgeNet.__slen(13), 5
      equal KnowledgeNet.__slen(14), 5
      equal KnowledgeNet.__slen(15), 5
      equal KnowledgeNet.__slen(16), 6
      equal KnowledgeNet.__slen(17), 6
      equal KnowledgeNet.__slen(18), 6


  # test 'art'
  do ->
    knet_art = new KnowledgeNet(art_obj)

    test '对象构建', ->
      equal knet_art.points().length, 313
      equal knet_art.edges().length, 384

    test '获取 roots', ->
      equal knet_art.roots().length, 2

    test '清理 arts 多余边', ->
      equal knet_art.get_redundant_edges().length, 0

  # test '环路检查'