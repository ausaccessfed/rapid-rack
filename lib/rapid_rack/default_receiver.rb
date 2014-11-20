module RapidRack
  module DefaultReceiver
    def receive(env, claims)
      attrs = map_attributes(claims['https://aaf.edu.au/attributes'])
      store_id(env, subject(attrs).id)
      finish(env)
    end

    def map_attributes(attrs)
      attrs
    end

    def store_id(env, id)
      env['rack.session']['subject_id'] = id
    end

    def finish(env)
      redirect_to('/')
    end

    def redirect_to(url)
      [302, { 'Location' => url }, []]
    end

    def logout(env)
      env['rack.session'].clear
      redirect_to('/')
    end
  end
end
