import React from 'react';
import PropTypes from 'prop-types';
import {connect} from 'react-redux';
import moment from 'moment';
import {arrayMove} from 'react-sortable-hoc';
import {get, difference, xor, isEmpty, isEqual} from 'lodash';
import {Modal} from '../../index';
import {Button} from '../../UI';
import {SubNav, SlidingToolBar} from '../../UI/SubNav';
import {JumpToDropdown} from '../../Main';
import {FeaturedPlanningList} from './FeaturedPlanningList';
import {FeaturedPlanningSelectedList} from './FeaturedPlanningSelectedList';
import * as actions from '../../../actions';
import * as selectors from '../../../selectors';
import {MODALS} from '../../../constants';
import {gettext, onEventCapture} from '../../../utils';

export class FeaturedPlanningModalComponent extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            unselectedPlanningIds: [],
            selectedPlanningIds: [],
            notifications: [],
            highlights: [],
        };

        this.onAddToSelectedPlanning = this.onAddToSelectedPlanning.bind(this);
        this.onRemoveFromSelectedPlanning = this.onRemoveFromSelectedPlanning.bind(this);
        this.onSelectedItemsSortEnd = this.onSelectedItemsSortEnd.bind(this);
        this.onDateChange = this.onDateChange.bind(this);
        this.onCloseModal = this.onCloseModal.bind(this);
        this.onSave = this.onSave.bind(this);
        this.onNotificationsAccepted = this.onNotificationsAccepted.bind(this);
        this.removeHighlightForItem = this.removeHighlightForItem.bind(this);
        this.onSortStart = this.onSortStart.bind(this);
    }

    componentWillMount() {
        this.props.setFeaturePlanningInUse();
        if (!this.props.unsavedItems) {
            this.props.loadFeaturedPlanningsData(this.props.currentSearchDate);
        } else {
            // Loadng from ignore-cancel-save
            this.setState({
                unselectedPlanningIds: difference(this.props.featuredPlanningItems.map((i) => i._id),
                    this.props.unsavedItems),
                selectedPlanningIds: this.props.unsavedItems,
                dirty: true,
            });
        }
    }

    componentWillReceiveProps(nextProps) {
        if (!this.props.loading && nextProps.loading) {
            // Loading new set of data
            this.setState({
                selectedPlanningIds: [],
                unselectedPlanningIds: [],
                dirty: false,
            });
        } else if (this.props.loading && !nextProps.loading &&
            nextProps.featuredPlanningItems.length === nextProps.total) {
            // Loading complete
            this.setState(this.getNewState(nextProps));
        } else if (!this.props.loading) {
            if (!isEqual(this.props.featuredPlanningItem, nextProps.featuredPlanningItem)) {
                this.setState(this.getNewState(nextProps));
            }

            if (this.props.featuredPlanningItems !== nextProps.featuredPlanningItems) {
                // on update notifications
                const addedPlannings = difference(nextProps.featuredPlanIdsInList, this.props.featuredPlanIdsInList);
                const removedPlannings = difference(this.props.featuredPlanIdsInList, nextProps.featuredPlanIdsInList);
                const selectedPlanningIds = this.state.selectedPlanningIds.filter(
                    (id) => nextProps.featuredPlanIdsInList.includes(id));
                let unselectedPlanningIds = [...this.state.unselectedPlanningIds, ...addedPlannings];

                unselectedPlanningIds = unselectedPlanningIds.filter(
                    (id) => !removedPlannings.includes(id) && !selectedPlanningIds.includes(id));

                const notifications = [], highlights = [...addedPlannings];

                if (addedPlannings.length > 0) {
                    addedPlannings.forEach((id) => {
                        const item = nextProps.featuredPlanningItems.find((p) => p._id === id);

                        notifications.push(`Story with slugline '${item.slugline}' is added to the list`);
                    });
                }

                if (removedPlannings.length > 0) {
                    removedPlannings.forEach((id) => {
                        const item = this.props.featuredPlanningItems.find((p) => p._id === id);

                        notifications.push(`Story with slugline '${item.slugline}' is removed from the list`);
                    });
                }

                this.setState({
                    unselectedPlanningIds: unselectedPlanningIds,
                    selectedPlanningIds: selectedPlanningIds,
                    dirty: xor(get(this.props, 'featuredPlanningItem.items', []), selectedPlanningIds).length > 0,
                    notifications: notifications,
                    highlights: highlights,
                });
            }
        }
    }

    getNewState(props) {
        const planingIds = props.featuredPlanningItems.map((i) => i._id);

        return {
            unselectedPlanningIds: difference(planingIds, get(props, 'featuredPlanningItem.items', [])),
            selectedPlanningIds: get(props, 'featuredPlanningItem.date') ? props.featuredPlanningItem.items :
                planingIds,
            dirty: !get(props, 'featuredPlanningItem.date'),
            highlights: [],
        };
    }

    onDateChange(date) {
        this.props.loadFeaturedPlanningsData(date);
    }

    onAddToSelectedPlanning(item, event) {
        onEventCapture(event);
        let newIds = [...this.state.selectedPlanningIds];

        newIds.unshift(item._id);
        this.setState({
            selectedPlanningIds: newIds,
            unselectedPlanningIds: difference(this.state.unselectedPlanningIds, newIds),
            dirty: xor(get(this.props, 'featuredPlanningItem.items', []),
                newIds).length > 0,
            highlights: [...this.state.highlights, item._id],
        });
    }


    onRemoveFromSelectedPlanning(item, event) {
        onEventCapture(event);
        const newSelectedIds = this.state.selectedPlanningIds.filter((p) => p !== item._id);
        let newIds = [...this.state.unselectedPlanningIds];

        newIds.unshift(item._id);
        this.setState({
            selectedPlanningIds: newSelectedIds,
            unselectedPlanningIds: newIds,
            dirty: xor(get(this.props, 'featuredPlanningItem.items', []),
                newSelectedIds).length > 0,
            highlights: [...this.state.highlights, item._id],
        });
    }


    getUnSelectedPlannings() {
        return get(this.props, 'featuredPlanningItems', []).filter(
            (p) => this.state.unselectedPlanningIds.includes(p._id));
    }

    getSelectedPlannings() {
        return this.state.selectedPlanningIds.map((id) =>
            get(this.props, 'featuredPlanningItems', []).find((p) => p._id === id));
    }

    getListGroupProps(selected = true) {
        return selected ? this.getSelectedPlannings() : this.getUnSelectedPlannings();
    }

    onSave(tearDown) {
        let updates = {items: this.state.selectedPlanningIds};

        if (isEmpty(this.props.featuredPlanningItem)) {
            updates.date = this.props.currentSearchDate.clone();
            updates.date.set({
                hour: 0,
                minute: 0,
            });
            updates.tz = this.props.currentSearchDate.tz();
        }
        this.props.saveFeaturedPlanningForDate(updates);

        if (tearDown) {
            this.props.unsetFeaturePlanningInUse();
        }
    }

    // set cursor to move during whole drag
    onSortStart() {
        this.cursor = document.body.style.cursor;
        document.body.style.cursor = 'move';
    }

    onSelectedItemsSortEnd({oldIndex, newIndex}) {
        const newIds = arrayMove(this.state.selectedPlanningIds, oldIndex, newIndex);

        this.setState({
            selectedPlanningIds: newIds,
            dirty: !isEqual(get(this.props, 'featuredPlanningItem.items'), newIds),
        });
        document.body.style.cursor = this.cursor;
    }

    isReadOnly() {
        return this.props.currentSearchDate.isBefore(moment(), 'day');
    }

    onCloseModal() {
        if (!this.state.dirty) {
            this.props.unsetFeaturePlanningInUse();
        } else {
            this.props.saveDirtyData(this.state.selectedPlanningIds);
            this.props.openCancelModal({
                bodyText: gettext('Are you sure you want to exit Manging Featured Stories ?'),
                onIgnore: this.props.unsetFeaturePlanningInUse,
                onSave: this.onSave.bind(null, true),
                autoClose: true,
            });
        }
    }

    onNotificationsAccepted() {
        this.setState({notifications: []});
    }

    removeHighlightForItem(id, event) {
        onEventCapture(event);
        this.setState({highlights: this.state.highlights.filter((h) => h !== id)});
    }

    render() {
        const {
            inUse,
            currentSearchDate,
            lockedItems,
            dateFormat,
            timeFormat,
            loading,
            desks,
            users,
            defaultTimeZone,
        } = this.props;

        const emptyMsg = this.state.unselectedPlanningIds.length === 0 &&
            get(this.props, 'featuredPlanningItems.length', 0) > 0 ?
            gettext('No more available selections') :
            gettext('No available selections');

        const listProps = {
            highlights: this.state.highlights,
            onClick: this.removeHighlightForItem,
            lockedItems: lockedItems,
            currentSearchDate: currentSearchDate,
            readOnly: this.isReadOnly(),
            dateFormat: dateFormat,
            timeFormat: timeFormat,
            selectedPlanningIds: this.state.selectedPlanningIds,
            loadingIndicator: loading,
            desks: desks,
            users: users,
            onAddToSelectedFeaturedPlanning: this.onAddToSelectedPlanning,
            onRemoveFromSelectedFeaturedPlanning: this.onRemoveFromSelectedPlanning,
        };

        if (!inUse) {
            return null;
        }

        return (
            <Modal show={true} fill={true} onHide={this.onCloseModal}>
                <Modal.Header>
                    {<a className="close" onClick={this.onCloseModal}>
                        <i className="icon-close-small" />
                    </a>}
                    <h3>{gettext('Featured Stories')}</h3>
                </Modal.Header>
                <Modal.Body noPadding fullHeight noScroll>
                    <SubNav>
                        {this.state.notifications.length > 0 && <SlidingToolBar
                            onCancel={this.onNotificationsAccepted}
                            innerInfo={this.state.notifications.join(', ')}
                            rightCancelButton
                        />}
                        <JumpToDropdown
                            currentStartFilter={currentSearchDate}
                            setStartFilter={this.onDateChange}
                            defaultTimeZone={defaultTimeZone}
                            dateFormat="dddd LL" />
                        {this.props.loading && <div className="loading-indicator">{gettext('Loading')}</div>}
                    </SubNav>
                    <div className="grid">
                        <FeaturedPlanningList
                            { ...listProps }
                            items={this.getListGroupProps(false)}
                            emptyMsg={emptyMsg} />
                        <FeaturedPlanningSelectedList { ...listProps }
                            items={this.getListGroupProps()}
                            leftBorder
                            onSortEnd={this.onSelectedItemsSortEnd}
                            onSortStart={this.onSortStart} />
                    </div>
                </Modal.Body>
                <Modal.Footer>
                    <Button
                        text={gettext('Cancel')}
                        onClick={this.onCloseModal}
                    />
                    {this.state.dirty && <Button
                        color="primary"
                        text={gettext('Save')}
                        onClick={this.onSave.bind(null, false)}
                    />}
                </Modal.Footer>
            </Modal>
        );
    }
}

FeaturedPlanningModalComponent.propTypes = {
    actionInProgress: PropTypes.bool,
    modalProps: PropTypes.object,
    inUse: PropTypes.bool,
    getFeaturedPlanningsForDate: PropTypes.func,
    currentSearchDate: PropTypes.object,
    lockedItems: PropTypes.object,
    dateFormat: PropTypes.string,
    timeFormat: PropTypes.string,
    loadingIndicator: PropTypes.bool,
    desks: PropTypes.array,
    users: PropTypes.array,
    featuredPlanningItem: PropTypes.object,
    setFeaturePlanningInUse: PropTypes.func,
    unsavedItems: PropTypes.array,
    loadFeaturedPlanningsData: PropTypes.func,
    featuredPlanningItems: PropTypes.array,
    loading: PropTypes.bool,
    total: PropTypes.number,
    featuredPlanIdsInList: PropTypes.array,
    saveFeaturedPlanningForDate: PropTypes.func,
    unsetFeaturePlanningInUse: PropTypes.func,
    saveDirtyData: PropTypes.func,
    openCancelModal: PropTypes.func,
    defaultTimeZone: PropTypes.string,
};

FeaturedPlanningModalComponent.defaultProps = {featuredPlanningItem: {}};

const mapStateToProps = (state) => ({
    unsavedItems: selectors.featuredPlanning.unsavedItems(state),
    inUse: selectors.featuredPlanning.inUse(state),
    total: selectors.featuredPlanning.total(state),
    loading: selectors.featuredPlanning.loading(state),
    featuredPlanningItem: selectors.featuredPlanning.featuredPlanningItem(state),
    currentSearchDate: selectors.featuredPlanning.currentSearchDate(state),
    featuredPlanningItems: selectors.featuredPlanning.orderedFeaturedPlanningList(state),
    featuredPlanIdsInList: selectors.featuredPlanning.featuredPlanIdsInList(state),
    lockedItems: selectors.locks.getLockedItems(state),
    dateFormat: selectors.config.getDateFormat(state),
    timeFormat: selectors.config.getTimeFormat(state),
    loadingIndicator: selectors.main.loadingIndicator(state),
    users: selectors.general.users(state),
    desks: selectors.general.desks(state),
    defaultTimeZone: selectors.config.defaultTimeZone(state),
});

const mapDispatchToProps = (dispatch) => ({
    saveDirtyData: (ids) => dispatch(actions.planning.featuredPlanning.saveDirtyData(ids)),
    loadFeaturedPlanningsData: (date) =>
        dispatch(actions.planning.featuredPlanning.loadFeaturedPlanningsData(date)),
    getFeaturedPlanningItemForDate: (date) =>
        dispatch(actions.planning.featuredPlanning.getFeaturedPlanningItemForDate(date)),
    setFeaturePlanningInUse: (date) => dispatch(actions.planning.featuredPlanning.setFeaturePlanningInUse()),
    unsetFeaturePlanningInUse: (date) => dispatch(actions.planning.featuredPlanning.unsetFeaturePlanningInUse()),
    saveFeaturedPlanningForDate: (item) =>
        dispatch(actions.planning.featuredPlanning.saveFeaturedPlanningForDate(item)),
    openCancelModal: (modalProps) => (
        dispatch(actions.showModal({
            modalType: MODALS.IGNORE_CANCEL_SAVE,
            modalProps: modalProps,
        }))
    ),
});

export const FeaturedPlanningModal = connect(mapStateToProps, mapDispatchToProps)(FeaturedPlanningModalComponent);