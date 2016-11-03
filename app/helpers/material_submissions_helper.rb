module MaterialSubmissionsHelper
def wells_attributes_for(plate)
  memo = []
  plate.wells.each_with_index do |well, index|
    memo.push({
      :id => well.id.to_s,
      :position => well.position,
      :biomaterial_attributes => (well.biomaterial || Biomaterial.new)
    })
  end.sort do |w1,w2|
    w1.id <=> w2.id
  end
  memo
end

def plate_attributes_for(labwares)
  mlabware = {}
  labwares.each_with_index do |plate, plate_idx|
    mlabware[plate_idx.to_s] = {
      :id => plate.id.to_s,
      :barcode => plate.barcode,
      :wells_attributes => wells_attributes_for(plate)
    }
  end
  mlabware
end


end
