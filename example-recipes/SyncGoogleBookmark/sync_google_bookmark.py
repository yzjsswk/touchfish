from touchfish import *
from yfunc import *
import sys

host = sys.argv[1]
port = sys.argv[2]
support_path = sys.argv[3]

data_service = DataService(host=host, port=port)

fish_list = data_service.search_fish(tags=['bookmark'], page_size=999999)
exists_bookmark = {}
for fish in fish_list:
    try:
        exists_bookmark[fish.extra_info['guid']] = fish
    except:
        pass
_, r = ystr(support_path).find_last('Application Support')
google_support_path = f'{support_path[:r]}/Google/Chrome/Default'

bookmark_index = ystr().from_file(google_support_path+'/Bookmarks').json().to_dic()

bookmark_info = []
def search_url(d: dict):
    if d.get('type') == 'url':
            bookmark_info.append((d.get('guid'), d.get('name'), d.get('url')))
            return
    for _, v in d.items():
        if isinstance(v, dict):
            search_url(v)
        if isinstance(v, list):
            for e in v:
                if isinstance(e, dict):
                    search_url(e)
search_url(bookmark_index)

favicon_db_path = google_support_path + '/Favicons'
copy_favicon_db_path = support_path + '/SyncGoogleBookmarkCache'

import shutil
shutil.copyfile(favicon_db_path, copy_favicon_db_path)

favicon_db_handler = ystr(copy_favicon_db_path).filepath().db(only_read=True, auto_close=False)

def fetch_icon_from_google_db(url: str) -> bytes | None:
    res = favicon_db_handler.execute(f"select icon_id from icon_mapping where page_url='{url}';")
    if len(res) == 0 or len(res[0]) == 0:
        return None
    icon_id = res[0][0]
    res = favicon_db_handler.execute(f"select image_data from favicon_bitmaps where icon_id = {icon_id};")
    if len(res) == 0 or len(res[0][0]) == 0:
        return None
    return res[0][0]

def fetch_icon_with_python_sdk(url) -> bytes | None:
    import favicon
    import requests
    icons = favicon.get(url)
    if len(icons) == 0:
        return None
    icon_url = icons[0].url
    response = requests.get(icon_url)
    response.raise_for_status()
    return response.content

added_url = []
removed_url = []
update_url = []

for guid, name, url in bookmark_info:

    icon_data = fetch_icon_from_google_db(url=url)
    if icon_data != None:
        icon_md5 = ybytes(icon_data).md5()

    do_update = False

    if guid in exists_bookmark:
        fish = exists_bookmark[guid]
        del exists_bookmark[guid]
        if icon_data == None:
            continue
        if 'bookmark_icon_md5' in fish.extra_info and fish.extra_info['bookmark_icon_md5'] == icon_md5:
            continue
        else:
            data_service.expire_fish(fish.uid)
            if 'bookmark_icon_uid' in fish.extra_info:
                data_service.expire_fish(fish.extra_info['bookmark_icon_uid'])
            do_update = True
            
    md5__url = ystr(url).md5()
    fish_list = data_service.search_fish(identitys=[md5__url])
    if len(fish_list) > 0 and not fish_list[0].is_marked:
        data_service.expire_fish(identity=fish_list[0].uid)
    
    extra_info = {'guid': guid}
    if icon_data != None:
        extra_info['bookmark_icon_md5'] = icon_md5
        icon_uid = data_service.add_fish(
            fish_type=FishType.Image,
            fish_data=icon_data, 
            desc=f'Icon From {url} \n Add by Sync Google Bookmark', 
            tags=['icon'], 
            is_marked=True,
        )
        extra_info['bookmark_icon_uid'] = icon_uid
    data_service.add_fish(
        fish_type=FishType.Text,
        fish_data=ybytes.from_str(url),
        desc=name, 
        tags=['bookmark'], 
        is_marked=True, 
        extra_info=ystr().json().from_object(extra_info),
    )
    if do_update:
        update_url.append((name, url))
    else:
        added_url.append((name, url))

for guid, fish in exists_bookmark.items():
    data_service.expire_fish(fish.uid)
    removed_url.append((fish.desc, fish.text_data()))

# MessageCenter.send(
#     level='info', 
#     content=f'added {len(added_url)} urls, updated {len(update_url)} urls, removed {len(removed_url)} urls\nadded url={added_url}\nupdated_urls={update_url}\nremoved url={removed_url}',
#     title='Sync Google Bookmark',
#     source='com.yzjsswk.SyncGoogleBookmark',
# )