class TestErrorHandler
  def handle(_env, _error)
    [400, {}, ['Error!']]
  end
end
