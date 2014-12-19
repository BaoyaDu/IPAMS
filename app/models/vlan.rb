class Vlan < ActiveRecord::Base
  require 'csv'

  validates :vlan_number, :vlan_name,:vlan_description, presence: true
  validates :gateway, :static_ip_start, :static_ip_end, presence: true, uniqueness: true

  belongs_to :lan
  has_many :addresses, dependent: :destroy
  has_many :reserved_addresses, dependent: :destroy
  has_many :users, through: :addresses

  # See http://richonrails.com/articles/importing-csv-files
  # Import a csv file into table vlans
  # Check to see if the VLAN already exists in the database. if it does,
  # it will then attempt to update the existing VLAN. If not, 
  # it will attempt to create a new VLAN.
  # The VLANs importing CSV template with 1st row as the headers:
  # lan_name   vlan_number vlan_name static_ip_start static_ip_end  subnet_mask   gateway	 vlan_description
  # Legacy LAN 23	   VLAN_23   192.168.23.0    192.168.23.255 255.255.255.0 192.168.23.254 Main Building
  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row| # CSV::Row is part Array &part Hash
      vhash = row.to_hash # temporary VLAN record hash

      # Find FK lan_id
      lan_id = self.find_lan_id(vhash[:lan_name])
     
      # Go to the next row if invalid lan_id was found 
      next unless lan_id > 0

      vhash[:lan_id] = lan_id # appends the lan_id FK
      # Remove lan_name field from the row as it's not a field of table vlans
      vhash.delete(:lan_name)
      
      # Validation, see http://guides.rubyonrails.org/active_record_validations.html
      # vlan.first.update_attributes(vhash)
      # Vlan.create!(vhash)
      # Need to feedback the result to the user in the future release
      tv = Vlan.new(vhash) # temporary VLAN record
      if tv.invalid? # invalid? triggers the validation
        next # no continue in Ruby!
      else
        tv.save
      end
    end
  end

  # Find FK lan_id with the given lan_name
  def self.find_lan_id(lan_name)
    lan_id = -999 # An impossible PK
    #lan = Lan.where({lan_name: lan_name}) # returnan ActiveRecord::Relation object
    lan = Lan.find_by lan_name: lan_name # return a Lan object
    if lan
      lani_id = lan.id
    else # Try creating a new Lan
      new_lan = Lan.create(lan_number: Lan.count + 1, lan_name: lan_name,
        lan_description: "Automatically created by IPAMS. Please edit!")
      lan_id = new_lan.id if new_lan.valid?      
    end
    return lan_id
  end
  
  # Deprecated on Dec. 19, 2014 as it's clumsy. Use rails validation instead.
  # Determine if a VLAN already exists.
  def self.vlan_exists(vhash_to_import = {})
    exist = false
    vlans = Vlan.all # Array
    vlans = vlans.to_a.map(&:serializable_hash) # to Hash
    vlans.each do |vlan|
      if vlan == vhash_to_import
        exist = true
        break
      end 
    end

    return exist  
  end
end

