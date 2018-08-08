import React from 'react';
import {
  Button,
  Container,
  Row,
  Col,
} from 'reactstrap';
import styled from 'styled-components';
import {
  LinkContainer,
  PageHeading,
  Section,
  SectionIcon,
  makeSection,
} from 'flight-reactware';
import FontAwesome from 'react-fontawesome';

import ContextLink from '../elements/ContextLink';

const sections = {
  whatIsIt: makeSection('What is Flight Console?', 'what-is-it', 'pink', 'question'),
};

const CallToAction = styled(({ children, className, icon, to }) => {
  return (
    <LinkContainer 
      className={className}
      to={to}
    >
      <Button
        color="success"
        size="lg"
      >
        <FontAwesome
          fixedWidth
          name={icon}
        />
        {children}
      </Button>
    </LinkContainer>
  );
})`
  text-align: center;
  margin-top: 20px;
  margin-bottom: 20px;
  font-family: "Montserrat", "Helvetica Neue", Helvetica, Arial, sans-serif;
`;

const Home = () => {
  return (
    <div>
      <Container fluid>
        <PageHeading
          overview="This service provides facilities to help manage and access your Alces Flight
          Center clusters."
          sections={Object.values(sections)}
          title="Welcome to the Alces Flight Center console service."
        />
      </Container>
      <Container>
        <Section
          overview="The Alces Flight Center console service provides access to an
          expanding suite of tools that ease the management of and access to your Alces Flight Center HPC clusters."
          section={sections.whatIsIt}
          title="What is the console service?"
        >
          <Row>
            <Col>
              <SectionIcon name="user" />
              <h4>
                Alces Flight Directory
              </h4>
              <p>
                Alces Flight Directory provides an easy-to-use command-line interface,
                accessible through an {' '}
                <ContextLink
                  linkSite="Console"
                  location="/directory"
                >
                  embeded terminal
                </ContextLink>{', '}
                giving you rapid access to user, group and host management across your compute estate.
              </p>
            </Col>
          </Row>
          <Row>
            <Col className="d-flex justify-content-center">
              <CallToAction
                icon="play-circle"
                to="/directory"
              >
                Open Alces Flight Directory console
              </CallToAction>
            </Col>
          </Row>
        </Section>
      </Container>
    </div>
  );
};

export default Home;
