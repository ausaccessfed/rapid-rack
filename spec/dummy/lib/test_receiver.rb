class TestReceiver
  def receive(_env, _claims)
    [200, {}, ['Permitted']]
  end

  def logout(_env)
    [200, {}, ['Logged Out!']]
  end

  def register_jti(jti)
    jti == 'accept'
  end
end
