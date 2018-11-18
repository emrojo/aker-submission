class Manifest::ProvenanceState
  attr_reader :state, :manifest, :user
  attr_reader :schema, :mapping, :content

  delegate :manifest_schema_field, to: :schema
  delegate :manifest_schema, to: :schema
  delegate :labwares, to: :manifest


  def initialize(manifest, user)
    @manifest = manifest
    @user = user

    @schema = Schema.new(self)
    @mapping = Mapping.new(self)
    @content = Content.new(self)
  end

  def apply(state)
    @state = (state.dup || _build_state)

    @schema.apply(@state)
    @mapping.apply(@state)
    @content.apply(@state)

    save
    @state
  end

  def save
    if valid?
      update(state[:updates])
    end
  end

  def update(updates)
    if updates
      if valid?
        debugger
        provenance = ProvenanceService.new(@manifest.manifest_schema)
        messages = provenance.set_biomaterial_data(@manifest, updates, @user)
        @manifest_update_state.apply_messages(messages)
      end
    end
  end

  def valid?
    @content.valid?
  end


  def apply_messages(messages)
    @content = {}
  end

  def _build_state
    {
      manifest: {
        id: @manifest.id,
        schema: nil,
        content: nil,
        mapping: nil
      }
    }
  end

end