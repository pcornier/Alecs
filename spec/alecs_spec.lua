local Alecs = require '../Alecs'

describe('Testing ALECS', function()
  local alecs
  local s1_called, s2_called, s3_called
  local s1_added

  it('returns a new Alecs instance', function()
    alecs = Alecs()
    assert.is_table(alecs.getSystems())
  end)

  it('can add systems', function()
    local s1 = { filter = { 'a', 'b' } }
    local s2 = { filter = { 'a' } }
    local s3 = {}
    function s1:added() s1_added = true end
    function s1:update(check) s1_called = check end
    function s2:update(check) s2_called = check end
    function s3:update(check) s3_called = check end
    function s1:process(e, d) e.a = e.a + d end
    function s2:process(e, d) e.a = e.a + d end
    alecs:addSystem(s1, 'groupA')
    alecs:addSystem(s2, 'groupB')
    alecs:addSystem(s3, 'groupA')
    assert.is_true(s1_added)
    assert.is_true(#alecs:getSystems() == 3)
  end)

  it('can trigger update events', function()
    alecs:update(true)
    assert.is_true(s1_called)
    assert.is_true(s2_called)
    assert.is_true(s3_called)
  end)


  it('can disable systems', function()
    alecs:update(false)
    alecs:status('groupA', false)
    alecs:update(true)
    assert.is_false(s1_called)
    assert.is_true(s2_called)
    assert.is_false(s3_called)
    alecs:status('groupA', true)
    alecs:update(false)
    assert.is_false(s1_called)
    assert.is_false(s2_called)
    assert.is_false(s3_called)
  end)

  it('can manage entities', function()
    local e1 = { a = 0, b = 0 }
    local e2 = { a = 0, id = 'e2' }
    alecs:addEntity(e1)
    alecs:addEntity(e2)
    alecs:update(2)
    assert.is_true(e1.a == 4)
    assert.is_true(e2.a == 2)
    alecs:removeEntity(e1)
    alecs:update(2)
    assert.is_true(e1.a == 4)
    assert.is_true(e2.a == 4)
    alecs:removeEntity(alecs:get('e2'))
    alecs:update(2)
    assert.is_true(e1.a == 4)
    assert.is_true(e2.a == 4)
  end)

  it('can fetch entities', function()
    assert.is_true(#alecs:getEntities() == 0)
    local e1 = { b = 0, id = 'test' }
    local e2 = { b = 3 }
    alecs:addEntity({ a = 0 })
    alecs:addEntity(e1)
    alecs:addEntity(e2)
    alecs:addEntity({ a = 0, b = 0 })
    assert.is_true(#alecs:filter({ 'b' }) == 3)
    assert.is_true(#alecs:filter({ 'a' }) == 2)
    assert.is_true(#alecs:filter({ 'a', 'b' }) == 1)
    assert.are.same(alecs:find('b', 3)[1], e2)
    assert.are.same(alecs:get('test'), e1)
  end)

  it('can message', function()
    local msg1, msg2
    alecs:register('say', function(d)
      msg1 = d
    end)
    alecs:register('say', function(d)
      msg2 = d .. ' there'
    end)
    alecs:emit('say', 'hello')
    assert.is_true(msg1 == 'hello')
    assert.is_true(msg2 == 'hello there')
  end)

end)
