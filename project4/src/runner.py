import os
from datetime import datetime

from parser import parse
from diversity import DiversityFinder

RES_DIR = os.path.join(os.path.dirname(__file__), "results")

ALGO_NAME = 'ea'


def main(csv_file):
    students = parse(csv_file)
    run_res_dir = os.path.join(RES_DIR, datetime.now().strftime("%Y%m%d-%H%M%S"))
    os.makedirs(run_res_dir)

    res_files = {
        "teaming1": os.path.join(run_res_dir, "teaming1.out"),
        "teaming2": os.path.join(run_res_dir, "teaming2.out"),
        "teaming3": os.path.join(run_res_dir, "teaming3.out"),
        "teaming4": os.path.join(run_res_dir, "teaming4.out")
    }

    for semester, studs in students.items():
        div = DiversityFinder(studs, ALGO_NAME)
        for teaming, teams in div.get_diverse_teams().items():
            with open(res_files[teaming], "a") as res_f:
                lines = ["{},{},{}\n".format(s_hash, team, semester)
                         for s_hash, team in teams]
                res_f.writelines(lines)


if __name__ == '__main__':
    print("\n========================")
    print("Finding diverse Teams...")
    print("========================\n")

    file_dir = os.path.dirname(__file__)
    file_ = os.path.join(file_dir, "..", "project4.csv")

    os.makedirs(RES_DIR, exist_ok=True)

    main(file_)
    print("Found all diverse Teams!")
