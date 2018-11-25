import React from 'react';
import {Box} from "react-bulma-components";
import Columns from "react-bulma-components/lib/components/columns";
import Heading from "react-bulma-components/lib/components/heading";
import Button from "react-bulma-components/lib/components/button";
import Icon from "react-bulma-components/lib/components/icon";
import './LambdaListItem.scss';
import LambdaListChart from "./LambdaListChart";
import Trend from "../../common/Trend";

const mockDataChart = [
  {hour: 12, runs: 2, timing: 7, failures: 1},
  {hour: 13, runs: 5, timing: 4, failures: 6},
  {hour: 14, runs: 3, timing: 12, failures: 3},
  {hour: 15, runs: 1, timing: 3, failures: 9}
];

const LambdaListItem = ({lambda, onItemClicked})=>(
  <Box>
    <Columns>
      <Columns.Column>
        <Heading size={4}>{lambda.name || "- noname -"}</Heading>
      </Columns.Column>
      <Columns.Column>
        <LambdaListChart data={mockDataChart} dataKey={"runs"}/>
        <Trend text="last hour" number={5} arrowIcon="angle-down"/>
      </Columns.Column>
      <Columns.Column>
        <LambdaListChart data={mockDataChart} dataKey={"timing"}/>
      </Columns.Column>
      <Columns.Column>
        <Button.Group>
          <Button color="info" onClick={onItemClicked}><Icon icon="edit"/></Button>
          <Button color="info"><Icon icon="edit"/></Button>
          <Button color="info"><Icon icon="edit"/></Button>
          <Button color="info"><Icon icon="cross"/></Button>
        </Button.Group>
      </Columns.Column>
    </Columns>
    </Box>
);


export default LambdaListItem