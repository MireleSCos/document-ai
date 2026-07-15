Rails.application.config.filter_parameters += %i[
  password token api_key authorization candidate_cpf cpf
]
