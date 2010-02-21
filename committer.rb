class Committer
  attr_accessor :name, :username, :email, :organization, :occupation, :url
  
  def initialize
    
  end
  
  def checkCompany company
    reg = Regexp.new(company, true)
    if @email
      if @email.match reg
        return true
      end
    end
    if @organization
      if @organization.match reg
        return true
      end
    end
    
    return false
  end
end