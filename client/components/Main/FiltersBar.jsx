import React from 'react';
import PropTypes from 'prop-types';

import {SubNav} from '../UI/SubNav';
import {ToggleFiltersButton, FiltersBox} from '.';

export const FiltersBar = (props) => (
    <SubNav>
        <ToggleFiltersButton
            filterPanelOpen={props.filterPanelOpen}
            toggleFilterPanel={props.toggleFilterPanel}
        />
        <FiltersBox
            activeFilter={props.activeFilter}
            setFilter={props.setFilter}
            enabledAgendas={props.enabledAgendas}
            disabledAgendas={props.disabledAgendas}
            selectAgenda={props.selectAgenda}
            currentAgendaId={props.currentAgendaId}
            showFilters={props.showFilters}
        />
    </SubNav>
);

FiltersBar.propTypes = {
    filterPanelOpen: PropTypes.bool.isRequired,
    toggleFilterPanel: PropTypes.func.isRequired,
    activeFilter: PropTypes.string,
    setFilter: PropTypes.func.isRequired,
    enabledAgendas: PropTypes.array,
    disabledAgendas: PropTypes.array,
    selectAgenda: PropTypes.func.isRequired,
    currentAgendaId: PropTypes.string.isRequired,
    addNewsItemToPlanning: PropTypes.object,
    showFilters: PropTypes.bool,
    showAgendaSelection: PropTypes.bool,

};
