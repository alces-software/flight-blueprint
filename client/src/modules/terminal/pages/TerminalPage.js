import React from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import {Container} from 'reactstrap';

import Terminal from '../components/Terminal';

const propTypes = {
  auth: PropTypes.object,
  columns: PropTypes.number,
  overview: PropTypes.node.isRequired,
  rows: PropTypes.number,
  socketIOPath: PropTypes.string.isRequired,
  socketIOUrl: PropTypes.string.isRequired,
  termProps: PropTypes.object,
  title: PropTypes.node.isRequired,
};

const PaddedContainer = styled(Container)`
  padding-top: 15px;
  padding-bottom: 15px;
`;

const TerminalPage = ({
  auth,
  columns = 80,
  overview,
  rows = 25,
  socketIOPath,
  socketIOUrl,
  termProps,
  title,
}) => {
  return (
    <PaddedContainer fluid>
      <Terminal
        auth={auth}
        columns={columns}
        rows={rows}
        {...termProps || {}}
        socketIOPath={socketIOPath}
        socketIOUrl={socketIOUrl}
      />
    </PaddedContainer>
  );
};

TerminalPage.propTypes = propTypes;

export default TerminalPage;
