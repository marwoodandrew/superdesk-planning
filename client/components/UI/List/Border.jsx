import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

export const Border = ({state}) => (
    <div className={classNames(
        'sd-list-item__border',
        state ? `sd-list-item__border--${state}` : null
    )} />
);

Border.propTypes = {
    state: PropTypes.oneOf([
        false,
        'success',
        'error',
        'locked',
        'active',
        'idle',
    ]),
};

Border.defaultProps = {state: false};