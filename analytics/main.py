import argparse
import logging

logger = logging.getLogger(__name__)

def get_args(cmd_args=None):
    """Configure commandline: where to get souce data -- qeury dw or existing csv files;
    where to save output files; Environment -- prod or statging; period:--start_time, end_time
    :return: namespace
    """
    commandline_parser = argparse.ArgumentParser(description='Data pipeline extraction and environment setup.')

    commandline_parser.add_argument('--env', choices = ['dev', 'preproduction', 'production'], default='dev', help='Deployment environment')
    commandline_parser.add_argument('--source', choices = ['Postgresdb', 'DuckDB', 'Local files'])
    commandline_parser.add_argument('--format', choices = ['Parquet', 'csv'])
    commandline_parser.add_argument('--start_date', help='Period start_date (YYYY-MM-DD')
    commandline_parser.add_argument('--end_date', help='Period end date (YYYY-MM-DD)')
    if cmd_args:
        return commandline_parser.parse_args(cmd_args)
    return commandline_parser.parse_args()


def main(cmd_args=None):
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    args = get_args(cmd_args)
    logger.info(f'env is {args.env}')


if __name__ == '__main__':
    main()