# frozen_string_literal: true

# Service to deal with inputting HMDMC for human samples
class EthicsService
  def initialize(manifest, flash)
    @manifest = manifest
    @flash = flash
  end

  def update(ethics_params, by_user)
    unless @manifest.any_human_material?
      return error 'This Manifest is not listed as including human material.'
    end

    confirmed_not_req = (ethics_params[:confirm_hmdmc_not_required].to_i == 1)

    if confirmed_not_req
      @manifest.set_hmdmc_not_required(by_user)
    else
      return error 'Either "Not required" or an HMDMC number must be specified per sample.'
    end

    @manifest.labwares.each(&:save!)
    @manifest.update_attributes!(status: 'dispatch')

    true
  end

  private

  def error(message)
    @flash[:error] = message
    false
  end
end
