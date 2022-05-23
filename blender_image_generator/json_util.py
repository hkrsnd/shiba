import glob
import shutil
from datetime import datetime

import bpy
import cv2
import sys
import os
import json

import numpy
import numpy as np
from pycocotools import mask as maskUtils

from blender_image_generator.get_b_box import get_b_box

"""
largely copied from CLVR and CLEVR-HANS
    """


def encodeMask(M):
    """
    Encode binary mask M using run-length encoding and compute uncompressed rle
    :param   M (bool 2D array)  : binary mask to encode
    :return: R (object RLE)     : run-length encoding of binary mask
    """
    [h, w] = M.shape
    M = M.flatten(order='F')
    N = len(M)
    counts_list = []
    pos = 0
    # counts
    counts_list.append(1)
    diffs = np.logical_xor(M[0:N - 1], M[1:N])
    for diff in diffs:
        if diff:
            pos += 1
            counts_list.append(1)
        else:
            counts_list[pos] += 1
    # if array starts from 1. start with 0 counts for 0
    if M[0] == 1:
        counts_list = [0] + counts_list

    rle = {'size': [h, w],
           'counts': counts_list,
           }
    # compute compressed rle
    rle = maskUtils.frPyObjects(rle, rle.get('size')[0], rle.get('size')[1])
    # decode the bytes object to str
    rle['counts'] = rle.get('counts').decode('utf-8')
    return rle


def restore_img(m_train, t_num, train_col, base_scene):
    blender_objects = {}
    for obj in bpy.data.objects:
        if obj.pass_index in blender_objects:
            blender_objects[obj.pass_index].append(obj)
        else:
            blender_objects[obj.pass_index] = [obj]
    cars = m_train.m_cars
    obj_mask = {}
    base_path = f'tmp/tmp_graph_output/{train_col}/{base_scene}/'
    for car in cars:
        car_number = car.get_car_number()
        current_car = "car_" + str(car_number)
        obj_mask[current_car] = {}

        obj_mask[current_car]["mask"] = {}
        path = base_path + f't_{t_num}_car_{car_number}'
        try:
            objects = blender_objects[car.get_index('roof')]
        except Exception:
            objects = []
        objects += blender_objects[car.get_index('wheels')] + blender_objects[car.get_index('car')]
        for i in range(car.get_load_number()):
            objects += blender_objects[car.get_index("payload" + str(i))]
        b_box = get_b_box(bpy.context, objects)
        obj_mask[current_car]["mask"] = encodeMask(cv2.imread(path + '/Image0001.png')[:, :, 0])
        obj_mask[current_car]["b_box"] = b_box
        obj_mask[current_car]["world_cord"] = car.get_blender_world_cord('car')
        os.system('rm -r {}'.format(path))

        path = base_path + f't_{t_num}_car_{car_number}_roof'
        obj_mask[current_car]["roof"] = {}
        obj_mask[current_car]["roof"]["label"] = car.get_blender_roof()
        if car.get_blender_roof() != 'none':
            index = car.get_index('roof')
            objects = blender_objects[index]
            b_box = get_b_box(bpy.context, objects)
            obj_mask[current_car]["roof"]["b_box"] = b_box
            obj_mask[current_car]["roof"]["mask"] = encodeMask(cv2.imread(path + '/Image0001.png')[:, :, 0])
            obj_mask[current_car]["roof"]["world_cord"] = car.get_blender_world_cord('roof')

        os.system('rm -r {}'.format(path))

        path = base_path + f't_{t_num}_car_{car_number}_wall'
        index = car.get_index('wall')
        objects = blender_objects[index]
        b_box = get_b_box(bpy.context, objects)
        obj_mask[current_car]["wall"] = {}
        obj_mask[current_car]["wall"]["label"] = car.get_blender_wall()
        obj_mask[current_car]["wall"]["b_box"] = b_box
        obj_mask[current_car]["wall"]["mask"] = encodeMask(cv2.imread(path + '/Image0001.png')[:, :, 0])
        obj_mask[current_car]["wall"]["world_cord"] = car.get_blender_world_cord('wall')
        os.system('rm -r {}'.format(path))

        path = base_path + f'/t_{t_num}_car_{car_number}_wheels'
        # compute uncompressed rle from binary mask
        index = car.get_index('wheels')
        objects = blender_objects[index]
        b_box = get_b_box(bpy.context, objects)
        obj_mask[current_car]["wheels"] = {}
        obj_mask[current_car]["wheels"]["label"] = car.get_car_wheels()
        obj_mask[current_car]["wheels"]["mask"] = encodeMask(cv2.imread(path + '/Image0001.png')[:, :, 0])
        obj_mask[current_car]["wheels"]["b_box"] = b_box
        obj_mask[current_car]["wheels"]["world_cord"] = car.get_blender_world_cord('wheels')
        os.system('rm -r {}'.format(path))

        obj_mask[current_car]["color"] = {}
        color = car.get_blender_car_color()[0] if isinstance(car.get_blender_car_color(),
                                                             list) else car.get_blender_car_color()
        obj_mask[current_car]["color"]["label"] = color

        obj_mask[current_car]["length"] = {}
        obj_mask[current_car]["length"]["label"] = car.get_car_length()

        for i in range(car.get_load_number()):
            path = base_path + f't_{t_num}_car_{car_number}_payload{i}'
            payload = "payload_" + str(i)
            b_box = get_b_box(bpy.context, objects)
            index = car.get_index("payload" + str(i))
            objects = blender_objects[index]
            obj_mask[current_car][payload] = {}
            obj_mask[current_car][payload]["label"] = car.get_blender_payload()
            obj_mask[current_car][payload]["mask"] = encodeMask(cv2.imread(path + '/Image0001.png')[:, :, 0])
            obj_mask[current_car][payload]["b_box"] = b_box
            obj_mask[current_car][payload]["world_cord"] = car.get_blender_world_cord(payload)

            os.system('rm -r {}'.format(path))

    return obj_mask


def restore_depth_map(t_num, o_file, train_col, base_scene):
    path = f'tmp/depth/{train_col}/{base_scene}/t_{t_num}_depth'
    # depth_map = cv2.imread(path + '/Image0001.exr',  cv2.IMREAD_ANYCOLOR | cv2.IMREAD_ANYDEPTH)
    # reads depth map
    depth_map = cv2.imread(path + '/Image0001.exr', cv2.IMREAD_UNCHANGED)[:, :, 0]
    # set background to depth 100
    depth_map[depth_map > 100] = 100
    # 0.01 is the normalization factor used for drawing the depth maps
    # normalize between 0,255
    depth_map -= depth_map.min()
    depth_map *= 255/depth_map.max()

    cv2.imwrite(o_file, depth_map)
    # depth_map_2 = cv2.imread(o_file)[:, :, 0]
    os.system('rm -r {}'.format(path))
    # source = f'tmp/depth/t_{t_num}_depth/Image0001.exr'
    # shutil.move(source, o_file)
    # imageio.imwrite('float_img.exr', arr)


def merge_json_files(path):
    all_scenes = []
    for p in glob.glob(path + '/scenes/*_m_train.json'):
        with open(p, 'r') as f:
            all_scenes.append(json.load(f))
    output = {
        'info': {
            'date': datetime.now().strftime("%d/%m/%Y %H:%M:%S"),
            'version': '0.1',
            'license': None,
        },
        'scenes': all_scenes
    }
    json_pth = path + '/all_scenes/all_scenes.json'
    os.makedirs(path + '/all_scenes/', exist_ok=True)
    # args.output_scene_file.split('.json')[0]+'_classid_'+str(args.img_class_id)+'.json'
    with open(json_pth, 'w+') as f:
        json.dump(output, f)
