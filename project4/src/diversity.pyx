
from cython.parallel import prange

import numpy as np
cimport numpy as np

from fitness import Fitness
from fitness cimport Fitness
from rls import RLS
from rs import RS
from evolutionary_algorithm import EvolutionaryAlgorithm

algos = {
    'ea': lambda params: EvolutionaryAlgorithm(100, 5, **params),
    'rls': lambda params: RLS(**params),
    'rs': lambda params: RS(**params)
}

cdef class DiversityFinder:

    cdef int num_students
    cdef Student students[81]
    cdef dict dis_to_number
    cdef dict nat_to_number
    cdef str algo_name
    cdef int iterations

    def __init__(self, students, algo_name, iterations):
        self.num_students = len(students)

        self.algo_name = algo_name
        self.iterations = iterations

        self.dis_to_number = None
        self.nat_to_number = None
        self._convert_students(students)

        # Init student array
        cdef Student *s
        cdef int i

        for i in range(self.num_students):
            stud = students[i]
            s = &self.students[i]

            s.s_hash = stud[0].encode()
            s.sex = 0 if stud[1] == "m" else 1
            s.discipline = self.dis_to_number[stud[2]]
            s.nationality = self.nat_to_number[stud[3]]

    def create_fitness(self, other_teamings):
        unique_genders = 2
        unique_disciplines = len(self.dis_to_number)
        unique_nationalities = len(self.nat_to_number)
        fitness = Fitness(unique_genders, unique_disciplines, unique_nationalities, self.num_students, other_teamings)
        fitness.set_students(self.students)
        return fitness

    def _convert_students(self, students):
        self.dis_to_number = self._convert_disciplines(students)
        self.nat_to_number = self._convert_nationalities(students)

    def _convert_disciplines(self, students):
        disciplines = sorted({s[2] for s in students})
        return {dis: num for num, dis in enumerate(disciplines)}

    def _convert_nationalities(self, students):
        nationalities = sorted({s[3] for s in students})
        return {nat: num for num, nat in enumerate(nationalities)}

    def get_diverse_teams(self):
        teaming1 = self.create_random_teaming()
        print('Teaming 2')
        teaming2 = self.create_optimized_teaming([])
        print('Teaming 3')
        teaming3 = self.create_optimized_teaming([teaming2])
        print('Teaming 4')
        teaming4 = self.create_optimized_teaming([teaming2, teaming3])

        teams = {}
        for i, teaming in enumerate([teaming1, teaming2, teaming3, teaming4]):
            teams["teaming%d" % (i + 1)] = self.teaming_to_team(teaming)
        return teams

    cdef list create_random_teaming(self):
        return list(range(self.num_students))

    cdef list create_optimized_teaming(self, other_teamings):
        fitness = self.create_fitness(other_teamings)
        params = {
            'n_students': self.num_students,
            'fitness': fitness
        }
        algo = algos[self.algo_name](params)
        return algo.run(self.iterations)

    def teaming_to_team(self, teaming):
        teams = []
        team_number = 0
        for i in range(self.num_students):
            # teaming at i contains student number
            student_number = teaming[i]

            # Decode fom bytes and remove null bytes
            s_hash = self.students[student_number].s_hash.decode()[:32]

            # Each block of 5 students belong to one team
            team_number = i // 5

            # Last team has 6 people, if neccessary
            if i == 80:
                team_number = 15

            stud = (s_hash, team_number)
            teams.append(stud)

        return teams
