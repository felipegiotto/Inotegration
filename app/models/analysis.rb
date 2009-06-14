class Analysis < ActiveRecord::Base

  belongs_to :project
  has_many :results, :dependent => :destroy
  
  def situation_verbose
    if !finished?
      'Running'
    elsif results.all?{|result| result.situation == Result::APPROVED}
      'Approved'
    elsif results.any?{|result| result.situation == Result::FAIL}
      'Failed'
    else
      'Warnings'
    end
  end

  def make(nome, impact, &block)
    project.go_to_project_folder
    antes = Time.now
    begin
      result = block.call
      return if result.nil?
      r = self.results.build :situation => Result::APPROVED, :texto => result
    rescue Exception => e
      r = self.results.build :situation => impact, :texto => e.message
    end
    r.nome = nome
    r.tempo = Time.now - antes
    self.save
  end

end
