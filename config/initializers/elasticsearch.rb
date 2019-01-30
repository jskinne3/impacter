Elasticsearch::Model.client = Elasticsearch::Client.new({
  log: true,
  host: ENV['ELASTICSEARCH_URL'],
  port: '9243',
  user: 'elastic',
  password: ENV['ELASTICSEARCH_PW'],
})
