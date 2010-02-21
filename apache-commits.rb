require 'Nokogiri'
require './committer.rb'
require 'gruff'
class ApacheCommits
  attr_accessor :document, :authors, :authorList, :committers, :commitsByCompany, :totalcommits
  COMPANIES = ["IBM", "RED HAT", "APACHE" "EDU"]
  def initialize(file)
    @document = Nokogiri::XML(File.read(file))
    @authors = Hash.new(0)
    @committers = Array.new
    @commitsByCompany = Hash.new(0)
    @totalcommits = 0    
  end
  
  
  def read
    @document.css('author').each do |author|
      @authors[author.text.to_s] += 1
      @totalcommits +=1
    end
    parseAuthors
    crossReference nil
    reconcileDifferences
    p @commitsByCompany
    draw
  end
  
  def parseAuthors
    @authorList = File.read("authors.html")
    slices = %w{ <strong> </strong> <p> </p> <br /> </a>}
    slices.each do |str|
      while(@authorList.slice! str)
      end
    end
    while(@authorList.slice!(/<a href="(.)+">/))
    end
    while(@authorList.slice!(/<img(.)+/))
    end
    committer = NIL
    @authorList =  @authorList.each_line.map { |line|

      if line =~ /<a name=/
        @committers.push(committer) if committer
        committer = Committer.new
        line.slice! "<a name=\""
        committer.username = (line.slice!( /[A-z]*">/))[0..-3]
        line.slice!("Name:")
        line.strip!
        committer.name = line
        counter = 0
      end
      
      if line =~ /Email:/
        line.slice!("Email:")
        line.strip!
        committer.email = line
      end
      
      if line =~/URL:/
        line.slice!("URL:")
        line.strip!
        committer.url = line
      end
      
      if line =~/Organization:/
        line.slice!("Organization:")
        line.strip!
        committer.organization = line
      end
      
      if line =~/Occupation:/
        line.slice!("Occupation:")
        line.strip!
        committer.occupation = line
      end

      line
      
      }.join("")

  end 
  
  def crossReference companyList
    @committers.each do |cmtr|
      found = false
      
      #Handle a company list if passed in
      if companyList
        companyList.each do |company|
          if cmtr.checkCompany(company)
            found = true
            @commitsByCompany[company.to_s] += @authors[cmtr.username.to_s]
            break
          end
        end
        if !found
          @commitsByCompany[:other] += @authors[cmtr.username.to_s]
        end  
        
      else
        @commitsByCompany[cmtr.organization.to_s] += @authors[cmtr.username.to_s]
      end
        
    end
  end
  
  def reconcileDifferences
    total = 0 
    @commitsByCompany.each_value do |value|
      total += value
    end
    difference = @totalcommits - total
    @commitsByCompany[:unaccounted] = difference
  end
  
  def draw
    total = 0
    g = Gruff::Pie.new
    g.title = "Apache Commits By Company"
    @commitsByCompany.each_pair do |key, value|
      if !key.to_s.empty? and ((value/@totalcommits.to_f)>(0.015))
        g.data key.to_s, value
        total += value
      end 
    end
    g.data "Other", (@totalcommits - total)
    g.write("pie.png")
  end
end


reader = ApacheCommits.new("apache_commits.xml")
reader.read