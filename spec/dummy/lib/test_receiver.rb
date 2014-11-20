class TestReceiver
  def receive(_env, _claims)
  end

  def logout(_env)
    [200, {}, ['Logged Out!']]
  end

  def register_jti(_jti)
    false
  end
end
