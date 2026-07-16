module DocumentAi
  class PromptBuilder
    RULES = {
      "rg" => <<~TEXT,
        Para RG ou CIN:
        - confirme que é documento brasileiro de identidade;
        - verifique legibilidade e completude;
        - extraia nome, CPF quando visível, RG, nascimento, emissão e órgão emissor;
        - não trate aparência como prova de autenticidade oficial.
      TEXT
      "marriage_certificate" => <<~TEXT,
        Para certidão de casamento:
        - confirme que é uma certidão de casamento;
        - extraia nomes dos cônjuges, data, matrícula e cartório quando visíveis;
        - não confunda com certidão de nascimento ou declaração de união estável.
      TEXT
      "address_proof" => <<~TEXT,
        Para comprovante de endereço:
        - confirme que o documento contém nome, endereço, emissor e data;
        - exemplos: energia, água, telefone, internet, condomínio, IPTU ou extrato;
        - não aceite conversa, texto digitado ou imagem sem emissor verificável.
      TEXT
      "voter_registration" => <<~TEXT,
        Para título de eleitor:
        - confirme que é um título eleitoral brasileiro, e-Título ou comprovante eleitoral equivalente;
        - extraia nome, número do título, zona, seção, município e UF quando visíveis;
        - não confunda com RG, CPF, carteira de trabalho ou comprovante de votação.
      TEXT
      "diploma" => <<~TEXT
        Para diploma ou certificado acadêmico:
        - confirme que é diploma, certificado de conclusão ou declaração institucional de formação;
        - extraia nome do aluno, instituição, curso, grau/título, data e registro quando visíveis;
        - não aceite currículo, histórico escolar isolado ou imagem sem instituição identificável.
      TEXT
    }.freeze

    def self.call(expected_type:, context: {})
      <<~PROMPT
        Você analisa documentos para processo admissional brasileiro.
        Tipo esperado: #{expected_type}.

        #{RULES.fetch(expected_type)}

        Regras gerais:
        - todas as imagens pertencem ao mesmo envio;
        - use somente dados visíveis;
        - não invente;
        - não confirme autenticidade oficial;
        - marque readable=false quando dados obrigatórios não puderem ser lidos;
        - marque complete=false quando faltar lado, página ou região importante;
        - detected_type representa o documento realmente enviado;
        - datas devem usar YYYY-MM-DD quando determináveis;
        - confidence é a confiança na classificação e extração.

        Dados cadastrados:
        Nome: #{context[:candidate_name].presence || "não informado"}
        CPF: #{context[:candidate_cpf].presence || "não informado"}
      PROMPT
    end
  end
end
