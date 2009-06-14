class Analysis < ActiveRecord::Base

  belongs_to :project
  has_many :resultados, :dependent => :destroy
  
  def situation_verbose
    if resultados.all?{|result| result.situation == Resultado::APPROVED}
      'Approved'
    elsif resultados.any?{|result| result.situation == Resultado::FAIL}
      'Failed'
    else
      'Warnings'
    end
  end

  def analisar(nome, impact, &block)
    antes = Time.now
    begin
      resultado = block.call
      return if resultado.nil?
      r = self.resultados.build :situation => Resultado::APPROVED, :texto => resultado
    rescue Exception => e
      r = self.resultados.build :situation => impact, :texto => e.message
    end
    r.nome = nome
    r.tempo = Time.now - antes
  end

end
