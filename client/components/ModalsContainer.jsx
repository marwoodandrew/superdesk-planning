import React from 'react'
import { connect } from 'react-redux'
import { hideModal, deselectAllTheEventList } from '../actions'
import {
    AgendaModal,
    ConfirmationModal,
    NotificationModal,
    ItemActionConfirmationModal,
 } from './index'

import SortItemsModal from './SortItemsModal'

const modals = {
    CONFIRMATION: ConfirmationModal,
    CREATE_AGENDA: AgendaModal,
    EDIT_AGENDA: AgendaModal,
    NOTIFICATION_MODAL: NotificationModal,
    ITEM_ACTIONS_MODAL: ItemActionConfirmationModal,
    SORT_SELECTED: SortItemsModal,
}

export function Modals({ modalType, modalProps, handleHide }) {
    if (modalType) {
        return React.createElement(modals[modalType], {
            handleHide,
            modalProps,
        })
    } else {
        return null
    }
}


Modals.propTypes = {
    modalType: React.PropTypes.string,
    modalProps: React.PropTypes.object,
    handleHide: React.PropTypes.func.isRequired,
}

const mapStateToProps = (state) => ({
    modalType: state.modal.modalType,
    modalProps: state.modal.modalProps,
})
const mapDispatchToProps = (dispatch) => ({
    handleHide: (deselectEvents) => {
        dispatch(hideModal())
        if (deselectEvents) {
            dispatch(deselectAllTheEventList())
        }
    },
})
export const ModalsContainer = connect(mapStateToProps, mapDispatchToProps)(Modals)
