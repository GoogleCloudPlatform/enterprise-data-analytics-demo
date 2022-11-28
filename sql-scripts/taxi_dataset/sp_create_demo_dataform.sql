/*##################################################################################
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###################################################################################*/


/*
Use Cases:
    - To run the datafrom demo, first run this sp to create the necessary objects

Description: 
    - Create new dataset
    - Create table for pub_sub raw data
    - Create BigLake table

Clean up / Reset script:
    DROP SCHEMA IF EXISTS `${project_id}.dataform_demo` CASCADE;    
*/


-- Drop everythingi
DROP SCHEMA IF EXISTS `${project_id}.dataform_demo` CASCADE;


--- Create dataform_demo dataset 
CREATE SCHEMA `${project_id}.dataform_demo`
    OPTIONS (
    location = "${bigquery_region}"
    );


--- Create table for pub_sub raw data 
CREATE OR REPLACE TABLE `${project_id}.dataform_demo.taxi_trips_pub_sub`
(
    data STRING
)
PARTITION BY TIMESTAMP_TRUNC(_PARTITIONTIME, HOUR);


--- Create the BigLake table (there is no need to create the stored procedure like the video)
CREATE OR REPLACE EXTERNAL TABLE `${project_id}.dataform_demo.big_lake_payment_type`
    WITH CONNECTION `${project_id}.${bigquery_region}.biglake-connection`
    OPTIONS(
        uris=['gs://${bucket_name}/processed/taxi-data/payment_type_table/*.parquet'], 
        format="PARQUET"
    );


-- This replaces the Pub/Sub topic since we already have loaded the same data into a table
/*
{
    "ride_id": "1a80b0e2-2adb-431b-8455-aa7ee51839f3",
    "point_idx": 69,
    "latitude": 40.758160000000004,
    "longitude": -73.97748,
    "timestamp": "2022-11-28 19:15:31.062430+00",
    "meter_reading": 4.233383,
    "meter_increment": 0.06135338,
    "ride_status": "enroute",
    "passenger_count": 1
}
*/
INSERT INTO `${project_id}.dataform_demo.taxi_trips_pub_sub` (_PARTITIONTIME,data)
SELECT TIMESTAMP_TRUNC(timestamp, HOUR),
    CONCAT(
    "{ ",
    '"ride_id"',":",'"',ride_id,'", ',
    '"point_idx"',":",point_idx,", ",
    '"latitude"',":",latitude,", ",
    '"longitude"',":",longitude,", ",
    '"timestamp"',":",'"',timestamp,'", ',
    '"meter_reading"',":",meter_reading,", ",
    '"meter_increment"',":",meter_increment,", ",
    '"ride_status"',":",'"',ride_status,'", ',
    '"passenger_count"',":",passenger_count,
    " }") AS Data
 FROM `${project_id}.${bigquery_taxi_dataset}.taxi_trips_streaming`;