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

def getflaglist( funlist, flag ):
    tmp = []
    for i in funlist:
        if i.find( flag ) >= 0:
           tmp.append( i )

    return tmp

def replacespace( array, flag ):
     replace = []
     for i in array:
        pos = i.find( flag )
        if pos >= 0:
           t = i[pos:]
           l = i[:pos]
           t = re.sub( "[\s\t\n]", "", t)
           l = l + t
           replace.append( l )
        else:
            replace = array
            break

     return replace

def getlist( org, target, flag ):
    org = replacespace( org, flag )
    target = replacespace( target, flag )

    unlist = list(set(org))
    unlist.sort(key=org.index)

    tag = []
    if len(org) == len( unlist ):
        return target
    else:
        for item in unlist:
            for i in target:
                if i.find( item ) >= 0:
                    tag.append( i )
                    break

    return tag

def getfunc( filename ):
    f = open( filename, 'r' )

    flag = r'AE_JSHANDLED_SELECTOR'
    dic_fun = {}
    try:
        all_the_text = f.read()

        # 找类名
        interface = re.findall( r'@interface.*?end', all_the_text, flags=re.S|re.I )
        name = r''
        value = r''
        for item in interface:
           classname = re.findall( r'@interface\s*(\w+)', item, flags=re.S|re.I )
           if classname:
                name = classname[0]
                name = name.strip()

           funlist = re.findall(r'[-|\+].*?;', item, flags=re.S | re.I)
           value = getflaglist( funlist, flag )

           fg = re.findall(r'(AE_JSHANDLED_SELECTOR.*?);', item, flags=re.S | re.I)
           shortlist = getlist( fg, value, flag )

           if name and shortlist:
              dic_fun[name] = shortlist

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

            if sr_item and sr_item.group() and sr:
              sr = sr_item.group()[0] + sr

            # 分号之间到空格
            #mid = re.findall( r':\s*\(.*?\)\s*.*?[\n|\s+]', sr, flags=re.S )
            mid = re.sub( r':\s*\(.*?\)\s*.*?[\n|\s+]', ": ", sr, flags=re.S )
            # AE_JSHANDLED_SELECTOR之后的内容
            tail = re.search( r'AE_JSHANDLED_SELECTOR\((.*?)\)', mid, flags=re.S )
            if None != tail:
               tn = tail.groups()
               if len( tn ) == 1:
                   flag_r = "|" + tn[0]
                   fin = re.sub( r'AE_JSHANDLED_SELECTOR\((.*?)\)', repl=flag_r, string=mid, flags=re.S )
                   fin = re.sub( "[\n\s\t;]", "", fin )
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

print "update finish......................"


"""
dic_fun = getfunc( "Person.h" )
dic_value = trim_str( dic_fun )
print dic_value
"""
