"""The tutorial DAG:
https://airflow.apache.org/docs/apache-airflow/stable/tutorial/pipeline.html
"""
import datetime as dt
import logging
import tempfile

from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.postgres.operators.postgres import PostgresOperator
import pendulum
import requests

DATA_URL = "https://raw.githubusercontent.com/apache/airflow/main/docs/apache-airflow/tutorial/pipeline_example.csv"
MERGE_QUERY = """
    INSERT INTO employees
    SELECT *
    FROM (
        SELECT DISTINCT *
        FROM employees_temp
    ) AS tmp
    ON CONFLICT ("Serial Number") DO UPDATE
    SET "Serial Number" = excluded."Serial Number";
"""

log = logging.getLogger(__name__)

@dag(
    schedule_interval="0 0 * * *",
    start_date=pendulum.datetime(2021, 1, 1, tz="UTC"),
    catchup=False,
    dagrun_timeout=dt.timedelta(minutes=60)
)
def process_employee():
    create_table = PostgresOperator(
        task_id="create_employee",
        postgres_conn_id="airflow_db",
        sql="ddl/employees.sql",
    )

    @task
    def get_data():
        resp = requests.request("GET", DATA_URL)
        log.info(f"{len(resp.text)} bytes of data retrieved")
        postgres = PostgresHook("airflow_db")

        with tempfile.NamedTemporaryFile() as f:
            f.write(resp.content)
            
            with postgres.get_conn() as conn:
                with conn.cursor() as cur:
                    with open(f.name, "r") as reader:
                        cur.copy_expert(
                            "COPY employees_temp FROM STDIN WITH CSV HEADER DELIMITER AS ',' QUOTE '\"'",
                            reader
                        )
                    cur.execute("SELECT COUNT(*) FROM employees_temp;")
                    count = cur.fetchall()
                    log.info("%s records inserted into ingestion table", count)
                conn.commit()

    @task
    def merge_employees():
        try:
            postgres = PostgresHook("airflow_db")
            with postgres.get_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute(MERGE_QUERY)
                conn.commit()
            return 0
        except Exception as e:
            print(e)
            return 1
    
    create_table >> get_data() >> merge_employees()

dag = process_employee()

