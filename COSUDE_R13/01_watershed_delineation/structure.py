# -*- coding: utf-8 -*-
"""Create data structures for data models from CSV data (id, parent) - Adjacency List Model"""
"""Research article: Optimization of river network representation data models for web-based systems"""
"""DOI: http://dx.doi.org/10.1002/2016EA000224"""
"""id: HydroID, parent: NextDownID"""
"""Parent = 1 for root catchments (last catchment in a tree) or coastal catchments (NextDownID = -1)"""

__author__      = "Robert Szczepanek"
__email__       = "robert@szczepanek.pl"
__url__         = "https://github.com/Cracert/HydroNetBenchKit/blob/v1.0.0/script/structure.py"
__modified_by__ = "Jefferson Valencia Gómez <jefferson.valencia.gomez@gmail.com>"


import numpy as np
import csv
import time

DATA_FOLDER = 'C:/Users/jvalenciag/Desktop'
DATA_FILE = 'src_microwatersheds.csv'


def read_data(folder_path=DATA_FOLDER, file_name=DATA_FILE):
    """ Read source data into numpy array"""

    data = np.loadtxt(folder_path + '/' + file_name,
                      delimiter=",", skiprows=1, dtype=int)
    # sort by first column  http://stackoverflow.com/questions/2828059/sorting-arrays-in-numpy-by-column
    data = data[data[:, 0].argsort()]

    return data


def path_enumeration(data, folder_path=DATA_FOLDER, csv_file_name='path_enumeration.csv'):
    """ Create path enumeration structure from source data"""

    """ TIP: Default separator is /
        To replace in generated file '/' with '.' use:
        sed 's/\//./g' <path_enumeration.csv >path_enumeration2.csv
    """

    path_enum = {}  # dictionary {id, path}

    start = time.clock()
    first_column = data[:, 0]
    #for row in data[10000:11000]:
    for row in data:
        # if row[0] != 458327:      # for issue #27 testing purposes
        #    continue
        n = 0
        n_limit = 2000    # limit number of levels
        i = 999
        id = row[0]

        parent = row[1]
        path_enum[id] = str(parent)

        while i > 1 and n < n_limit:
            # find parent for id
            i = np.searchsorted(first_column, parent)
            parent = data[i][1]
            n += 1

            path_enum[id] = str(parent) + '/' + path_enum[id]

    end = time.clock()
    print 'path enumeration {} [s]'.format(end - start)

    # save results in file
    start = time.clock()
    #for key, value in path_enum.iteritems():
    #    print key, value
    with open(folder_path + '/' + csv_file_name, 'wb') as f:
        w = csv.writer(f, quotechar='"', quoting=csv.QUOTE_NONNUMERIC)
        w.writerow(['id', 'path'])
        w.writerows(path_enum.items())

    end = time.clock()
    print 'save csv data {} [s]'.format(end - start)


def stream_side(id, data):
    """ Return order of children node (id); sorted by area descending from 0
        (children, area)
        "0" if id is main stream,
        "1" for second the biggest subbasin,
        ...
    """

    # sort node by area
    s = sorted(data, key=lambda data: data[1], reverse=True)

    side = "0"
    for i, val in enumerate(s):
        if val[0] == id:
            side = str(i)

    return side


def test_stream_side():
    """ Test stream_side function
    """

    # (children, area)
    data = [(10, 200),
            (20, 300),
            (30, 150),
            (40, 50)]
    # correct results
    result = {10: "1", 20: "0", 30: "2", 40: "3"}

    for x in result:
        #print x, result[x], stream_side(x, data)
        assert (result[x] == stream_side(x, data)), \
            "Stream side failed for node {}.".format(x)


def stream_model(data):
    """ Create stream model structure from source data"""

    path_enum = {}  # (id, root, parent, path, up_area)

    start = time.clock()
    first_column = data[:, 0]

    # prepare dict with (children, area) for each node
    child = {}
    for row in data:
        try:
            child[row[1]].append((row[0], row[2]))
        except:
            child[row[1]] = [(row[0], row[2])]

    # test if max_nr_children <= 10; except id=1 (top level) and id=0 (root)
    max_nr_children = max([len(v) for (k, v) in child.iteritems() if k > 1])
    if max_nr_children > 10:
        print 'Number of children for some nodes exceeds maximum (10).'
        print 'Further calculations not possible.'
        return

    #for row in data[39:45]:
    for row in data:
        n = 0
        n_limit = 2000    # limit number of levels
        id = row[0]

        # test only selected nodes
        #if id not in (605105, 604199, 605021):
        #    continue

        temp_id = id
        parent_first = row[1]
        parent = parent_first
        area = row[2]
        root = 1        # root node

        if id == 1:  # top level watershed - omit
            continue
        elif parent == 1:   # root nodes/watersheds
            side = stream_side(temp_id, child[parent])
            path_enum[id] = (root, parent_first, side, area)
            continue

        while parent > 1 and n < n_limit:

            # append side to path
            side = stream_side(temp_id, child[parent])
            try:
                path_enum[id] = side + '.' + path_enum[id]
            except:
                path_enum[id] = side

            # find parent for id
            i = np.searchsorted(first_column, parent)
            temp_id = data[i][0]
            parent = data[i][1]
            n += 1

            if parent == 1:   # exclude 0 (virtual top level)
                try:
                    root = temp_id
                    path_enum[id] = str(temp_id) + '.' + path_enum[id]
                except:
                    print str(data[i][0])

        path_enum[id] = (root, parent_first, path_enum[id], area)

    end = time.clock()
    print 'stream model {} [s]'.format(end - start)

    # save results in file
    start = time.clock()
    with open(DATA_FOLDER + 'stream_network.csv', 'wb') as f:
        f.write('id,root,parent,path,up_area\n')
        for key, value in path_enum.iteritems():
            s = '{},{},{},"{}",{}\n'.format(key,
                value[0], value[1], value[2], value[3])
            f.write(s)
    end = time.clock()
    print 'save csv data {} [s]'.format(end - start)


def find_parent(data, id):
    """ Find parent id for path enumeration"""

    return np.searchsorted(data, id)


if __name__ == "__main__":

    #test_stream_side()

    # path enumeration network model
    start = time.clock()
    x = read_data()
    end = time.clock()
    print 'read csv data {} [s]'.format(end - start)
    path_enumeration(x)

    # stream network model
    """
    start = time.clock()
    x = read_data('src-area.csv')
    end = time.clock()
    print 'read csv data {} [s]'.format(end - start)
    stream_model(x)
    """