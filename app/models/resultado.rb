class Resultado < ActiveRecord::Base

  APPROVED = 1
  WARNING = 2
  FAIL = 3
  
  belongs_to :analysis
  
  def situation_verbose
    case situation
    when APPROVED; 'Approved'
    when WARNING; 'Warnings'
    when FAIL;   'Failed'
    end
  end
  
end
