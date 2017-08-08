
# -*- coding: utf-8 -*-
import re
import os
import plistlib

def walk_dir(rootDir, dir_list):
    for lists in os.listdir(rootDir):
        path = os.path.join(rootDir, lists)

        if os.path.isdir(path):
            walk_dir(path, dir_list)
        if os.path.isfile(path):
            pos = path.endswith(r'.h')
            if pos >= True:
              #print path
              dir_list.append( path )

def getfunc( filename ):
    f = open( filename, 'r' )

    dic_fun = {}
    try:
        all_the_text = f.read()

        # 找类名
        interface = re.findall( r'@interface.*?end', all_the_text, flags=re.S|re.I )
        name = r''
        value = r''
        for item in interface:
           classname = re.findall( r'@interface.*?[:|\n].*?[:|\n]', item, flags=re.S|re.I )

           if len( classname ) > 0 :
             name = classname[0].replace( "@interface", "" )
             name = name.replace( '\n', "" )
             pod = name.find( ':' )
             if pod > 0:
                 name = name[:pod]
             name = name.strip()

           value = re.findall( r'[-|\+].*?AE_JSHANDLED_SELECTOR.*?;', item, flags=re.S|re.I )

           if len(name) > 0 and len(value) > 0:
              dic_fun[name] = value

    finally:
        f.close()

    return dic_fun


def trim_str( dic_fun ):
    dic_value = {}
    for item in dic_fun:
        v = dic_fun[item]
        change_list = []
        for fun in v:
            # 去+ 后的()
            sr_item = re.search( r'[-|\+]\s*\(.*?\)', fun )
            sr = re.sub( r'[-|\+]\s*\(.*?\)', "", fun )

            if len(sr_item.group()) > 0 and len(sr) > 0:
              sr = sr_item.group()[0] + sr

            # 分号之间到空格
            #mid = re.findall( r':\s*\(.*?\)\s*.*?[\n|\s+]', sr, flags=re.S )
            mid = re.sub( r':\s*\(.*?\)\s*.*?[\n|\s+]', ": ", sr, flags=re.S )
            # AE_JSHANDLED_SELECTOR之后的内容
            tail = re.search( r'AE_JSHANDLED_SELECTOR\((.*?)\)', mid, flags=re.S )
            if None != tail:
               tn = tail.groups()
               if len( tn ) == 1:
                   flag = "|" + tn[0]
                   fin = re.sub( r'AE_JSHANDLED_SELECTOR\((.*?)\)', repl=flag, string=mid, flags=re.S )
                   fin = re.sub( "\n", "", fin )
                   fin = re.sub( "\r\n", "", fin )
                   fin = re.sub( "\s", "", fin )
                   fin = re.sub( ";", "", fin )
                   fin = re.sub( "\t", "", fin )
                   change_list.append( fin )
            dic_value[ item ] = change_list

    return dic_value


def mergedic( file_dic ):
    dic_dest = {}
    list_class = []
    for classname in file_dic:
        list_class.append( classname )
        dic_cur = file_dic[classname]
        if len(dic_dest) == 0:
            dic_dest = dic_cur
        else:
            dic_dest = dict(dic_dest, **dic_cur)

    return dic_dest

def update_plist( dic_class ):
    try:
       plist = homedir + "/PROJECT-Info.plist"
       p = plistlib.readPlist(plist)

       p["AEJavaScriptHandledMethods"] = dic_class
       plistlib.writePlist(p, plist)
    except:
        print("Oh no!  Failure :(")


homedir = os.path.split(os.path.realpath(__file__))[0]
pdir_pos = homedir.rfind( r'/' )
if pdir_pos >= 0:
  current_dir = homedir[:pdir_pos]

dir = []
walk_dir( current_dir, dir )

file_dic = {}
for i in dir:
    dic_fun = getfunc(i)
    if len( dic_fun ) > 0:
        dic_value = trim_str(dic_fun)
        file_dic[i] = dic_value
        print file_dic

dic = mergedic( file_dic )
if len( dic ) > 0 :
    update_plist( dic )


"""
dict1={1:[1,11,111],2:[2,22,222]}
dict2={3:[3,33,333],4:[4,44,444]}
dicc = {}
dicc['a'] = dict1
dicc['b'] = dict2
dic = mergedic( dicc )
"""
print "update finish......................"


"""
dic_fun = getfunc( "Person.h" )
dic_value = trim_str( dic_fun )
print dic_value
"""
