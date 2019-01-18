import React from "react"
import {Fragment} from "react"
import { connect } from 'react-redux'
import classNames from 'classnames'

import StateSelectors from '../selectors'
import LabwareTabs from './labware_tabs'
import { LabwareContentInput } from './labware_content_input'


const logName = (name) => {  }

const LabwareContentHeaderComponent = (props) => {
  const requiredMark = props.isRequiredField ? (<span style={{color: "red"}}>*</span>) : null

  return(
    <th style={{whiteSpace: "nowrap"}}>
      { props.friendlyName }{ requiredMark }
    </th>
  )
}

const LabwareContentHeader = connect((state, ownProps) => {
  return {
    friendlyName: StateSelectors.schema.friendlyNameFor(state, ownProps.fieldName),
    isRequiredField: StateSelectors.schema.isRequiredField(state, ownProps.fieldName)
  }
})(LabwareContentHeaderComponent)


class LabwareContentCellComponent extends React.Component {
  /*shouldComponentUpdate(nextProps, nextState) {
    const val = StateSelectors.content.selectedValueAtCell(this.state, this.props.labwareIndex, this.props.address, this.props.fieldName)
    const nextVal = StateSelectors.content.selectedValueAtCell(nextState, nextProps.labwareIndex, nextProps.address, nextProps.fieldName)
    return (val !== nextVal)
  }*/
  render() {
    logName('LabwareContentCellComponent')
    const props = this.props
    return (
      <td data-psd-schema-validation-name={props.fieldName}>
        <div className={ classNames({
                'form-group': true,
                'has-error': props.displayError,
                'has-warning': props.displayWarning
              }
            )
          }
          style={{position: "relative"}}>

          <LabwareContentInput
            labwareIndex={props.labwareIndex}
            address={props.address}
            fieldName={props.fieldName} />
        </div>
      </td>
    )
  }
}

const mapStateToPropsLabwareContentCell = ((hasInputMessages, hasInputErrors) => {
  return (state, ownProps) => {
    const hasMessages = hasInputMessages(state, ownProps)
    const hasErrors = hasInputErrors(state, ownProps)

    return {
      labwareIndex: ownProps.labwareIndex,
      address: ownProps.address,
      fieldName: ownProps.fieldName,
      displayError: hasMessages && hasErrors,
      displayWarning: hasMessages && !hasErrors
    }
  }
})(StateSelectors.content.buildCheckInputMessages(), StateSelectors.content.buildCheckInputErrors())

const LabwareContentCell = connect(mapStateToPropsLabwareContentCell)(LabwareContentCellComponent)

const LabwareContentAddressComponent = (props) => {
  logName('LabwareContentAddressComponent')
      /*data-psd-component-class='TaxonomyIdControl'
      data-psd-component-parameters={
        JSON.stringify({
          taxonomyServiceUrl: props.taxonomyServiceUrl,
          relativeCssSelectorSciName: 'td[data-psd-schema-validation-name=scientific_name] input',
          relativeCssSelectorTaxId: 'td[data-psd-schema-validation-name=taxon_id] input',
          cachedTaxonomies: {}
        })
      }*/

  return(
    <tr
      data-labware-index={ props.labwareIndex } data-address={ props.address }>
      <td>{ props.address }</td>

      {props.fieldsToShow.map((fieldName, pos) => {
        return <LabwareContentCell
          labwareIndex={props.labwareIndex}
          address={props.address} fieldName={fieldName}
                key={fieldName} />
      })}
    </tr>
  )
}

const LabwareContentAddress = connect((state, ownProps) => {
  return {
    labwareIndex: ownProps.labwareIndex,
    address: ownProps.address,

    fieldsToShow: StateSelectors.schema.fieldsToShow(state),
    taxonomyServiceUrl: state.services.taxonomy_service_url,
  }
})(LabwareContentAddressComponent)

class LabwareContentAddresses extends React.Component {
  shouldComponentUpdate(nextProps, nextState) {
    const update = (nextProps.selectedTabPosition == this.props.position)
    return update
  }
  render() {
    logName('LabwareContentAddresses')
    const props = this.props
    return props.positionsForLabware.map((address, posAddress) => {
      return (
        <LabwareContentAddress key={address}
          labwareIndex={props.position}
          address={address}  />
      )
    })
  }
}

const LabwareContentComponent = (props) => {
  logName('LabwareContentComponent')
  return(
    <div role="tabpanel"
      className={classNames({"tab-pane": true, "active": (props.selectedTabPosition === props.position)})}
      id={"Labware"+ props.labwareIndex}>

      <div style={{overflow: "scroll"}} className="material-data-table">

        <table className="table table-condensed table-striped"
               data-psd-component-class={
                JSON.stringify(["LoadTable", "DataTableSchemaValidation"])
              }
               data-psd-component-parameters={JSON.stringify([{
                manifest_id: props.manifestId
                }, {
                  schemaJson: props.schema,
                  material_schema_url: props.materialSchemaUrl
                }
                ])}>
          <thead>
            <tr>
              <th></th>
              { props.fieldsToShow.map((name, pos) => {
                return (
                  <LabwareContentHeader fieldName={name} key={name} />
              )})}
            </tr>
          </thead>

          <tbody>
            <LabwareContentAddresses
              positionsForLabware={props.positionsForLabware}
              selectedTabPosition={props.selectedTabPosition} position={props.position} />
          </tbody>
        </table>
      </div>
    </div>
  )
}

const LabwareContent = connect((state, ownProps) => {
  return {
    labwareIndex: ownProps.labwareIndex,

    schema: StateSelectors.schema.get(state),
    manifestId: state.manifest.manifest_id,
    selectedTabPosition: StateSelectors.manifest.selectedTabPosition(state),
    positionsForLabware: StateSelectors.manifest.positionsForLabware(state, ownProps.labwareIndex),
    materialSchemaUrl: state.services.materials_schema_url,
    fieldsToShow: StateSelectors.schema.fieldsToShow(state)
  }
})(LabwareContentComponent)

const LabwareContentsComponent = (props) => {
  logName('LabwareContentsComponent')
  return (
    <div className="tab-content">
      { props.labwareIndexes.map((labwareIndex, pos) => {
        return (
          <LabwareContent key={labwareIndex} labwareIndex={labwareIndex} position={pos} />
        )
      })}
    </div>
    )
}

const LabwareContents = connect((state) => {
  logName('LabwareContents')
  return {
    labwareIndexes: StateSelectors.manifest.labwareIndexes(state)
  }
})(LabwareContentsComponent)

const ManifestContainersComponent = (props) => {
  logName('ManifestContainersComponent')
  if (props.manifestId) {
    return(
      <Fragment>
        <input type="hidden" value={ props.manifestId } name="manifest_id" />
        <LabwareTabs />
        <LabwareContents />
      </Fragment>
    )
  } else {
    return null
  }
}

const ManifestContainers = connect((state) => {
  return { manifestId: state.manifest.manifest_id }
})(ManifestContainersComponent)

export default ManifestContainers