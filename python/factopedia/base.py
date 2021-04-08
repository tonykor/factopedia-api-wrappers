"""
Factopedia API Python Wrapper base.py.
The base of the Factopedia Python library, all the features and the Factopedia class is here.
"""

from hashlib import md5
import requests

API_BASE_URL = 'api.factopedia.org'


class Factopedia:

    def __init__(self, token: str) -> None:
        self.token = token
        self.headers = {
            'Accept': 'application/json; q=1.0, */*; q=0.1'
        }

        self.valid_property_settings = ['category_id', 'unit_id', 'value', 'order_by', 'lang']
        self.valid_expand_values = ['properties', 'suggestedProperties', 'parents', 'children', 'countChildren']
        self.update_values = {
            'parent_id': 'parents[][Objects][id]'
        }

    def get_object_by_id(self, object_id: int, api_format: bool = False, expand: list = []) -> requests.Response:
        """
        Request an object by his id from Factopedia.
        Input: object_id: int, api_format: bool = False, expand: list = [].
        Output: requests.Response.
        """

        api_format = 'format=api' if api_format else ''

        for expand_value in expand:
            if expand_value not in self.valid_expand_values:
                raise KeyError(f'Invalid expand value "{expand_value}"')

        url_params = [] if not expand else [f'expand={",".join(expand)}']
        if api_format:
            url_params.append(api_format)

        url_params = '&'.join(url_params)
        url = self.get_url(f'objects/{object_id}?{url_params}')
        with requests.get(url, headers=self.headers) as response:
            return response

    def get_object(self, name: str = None, expand: list = [], parent_id: int = None, language: str = None, byproperty: str = None) -> requests.Response:
        """
        Request an object(s) by parameters from Factopedia.
        Input: name: str = None, expand: list = [], parent_id: int = None, language: str = None, byproperty: str = None.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        for expand_value in expand:
            if expand_value not in self.valid_expand_values:
                raise KeyError(f'Invalid expand value "{expand_value}"')

        url_params = [] if not expand else [f'expand={",".join(expand)}']
        get_by = [('name', name), ('parent_id', parent_id), ('lang', language), ('property', byproperty)]
        for key, value in get_by:
            if value:
                url_params.append(f'{key}={value}')

        url_params = '&'.join(url_params)
        url = self.get_url('objects') + '?' + url_params
        with requests.get(url, headers=self.headers) as response:
            return response

    def create_object(self, name: str, language: str, description: str = None, main_image: str = None, parent_id: int = None, children: list = [], aliases: list = [], images: list = [], properties: list = [], links: list = []) -> requests.Response:
        """
        Creates an object on Factopedia.
        Input: name: str, language: str, description: str = None, main_image: str = None, parent_id: int = None, children: list = [], aliases: list = [], images: list = [], properties: list = [], links: list = [].
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        data = self.gen_payload({}, name, language, description, main_image, parent_id, children, aliases, images, properties, links)
        payload = data['payload']
        files = data['files']

        url = self.get_url('objects')
        with requests.post(url, headers=self.headers, data=payload, files=files) as response:
            return response

    def update_object(self, object_id: int, name: str = None, language: str = None, description: str = None, main_image: str = None, parent_id: int = None, children: list = [], aliases: list = [], images: list = [], properties: list = [], links: list = []) -> requests.Response:
        """
        Updates an object by his id and provided parameters.
        Input: object_id: int, name: str = None, language: str = None, description: str = None, main_image: str = None, parent_id: int = None, children: list = [], aliases: list = [], images: list = [], properties: list = [], links: list = [].
        Output: requests.Response.
        """

        object_payload = self.get_object_by_id(object_id, expand=['properties']).json()
        name = object_payload['name']
        language = object_payload['lang']
        for _del in ['image', 'url', 'createdAt', 'createdBy', 'createdByGuest', 'version']:
            del object_payload[_del]

        for prop in object_payload['properties']:
            curr_prop = object_payload['properties'][prop]
            new_prop = {}
            new_prop['id'] = int(prop)
            new_prop['lang'] = curr_prop['name']['lang']
            try:
                if curr_prop['category']['id']:
                    new_prop['category_id'] = curr_prop['category']['id']
            except Exception as e:
                print(e)
            try:
                if curr_prop['unit']['id']:
                    new_prop['unit_id'] = curr_prop['unit']['id']
            except:
                pass
            new_prop['type'] = curr_prop['type']
            try:
                if type(curr_prop['value']) == list:
                    new_prop['value'] = [x.replace('&quot;', '"').replace('&amp;', '&') for x in curr_prop['value']]
                else:
                    new_prop['value'] = curr_prop['value'].replace('&quot;', '"').replace('&amp;', '&')
            except:
                new_prop['value'] = curr_prop['value']
            try:
                if curr_prop['order_by']:
                    new_prop['order_by'] = curr_prop['order_by']
            except:
                pass

            properties.append(new_prop)
            if 'link' in curr_prop and curr_prop['link']:
                links.append({'property': prop, 'url': curr_prop['link']})

        del object_payload['properties']
        for alias in object_payload['aliases']:
            aliases.append(alias)

        del object_payload['aliases']
        data = self.gen_payload(object_payload, name, language, description, main_image, parent_id, children, aliases, images, properties, links)
        payload = data['payload']
        files = data['files']

        url = self.get_url(f'objects/{object_id}')
        with requests.put(url, headers=self.headers, data=payload, files=files) as response:
            return response

    def get_property(self, name: str, language: str) -> requests.Response:
        """
        Returns a property by name and lagnuage.
        Input: name: str, language: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        url_params = f'filter[name]={name}&lang={language}'
        url = self.get_url('properties') + '?' + url_params

        with requests.get(url, headers=self.headers) as response:
            return response

    def create_property(self, name: str, language: str, property_type: str) -> requests.Response:
        """
        Creates a new property using the parameters.
        Input: name: str, language: str, property_type: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        payload = {
            'name': name,
            'lang': language,
            'type': property_type
        }

        url = self.get_url('properties')
        with requests.post(url, headers=self.headers, data=payload) as response:
            return response

    def get_unit(self, name: str, language: str) -> requests.Response:
        """
        Returns a unit by name and lagnuage.
        Input: name: str, language: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        url_params = f'filter[name]={name}&lang={language}'
        url = self.get_url('units') + '?' + url_params

        with requests.get(url, headers=self.headers) as response:
            return response

    def create_unit(self, name: str, language: str, unit_type: str) -> requests.Response:
        """
        Creates a new unit using the parameters.
        Input: name: str, language: str, unit_type: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        payload = {
            'name': name,
            'lang': language,
            'type': unit_type
        }

        url = self.get_url('units')
        with requests.post(url, headers=self.headers, data=payload) as response:
            return response

    def get_property_category(self, name: str, language: str) -> requests.Response:
        """
        Returns a property category by name and lagnuage.
        Input: name: str, language: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        url_params = f'filter[name]={name}&lang={language}'
        url = self.get_url('properties-categories') + '?' + url_params

        with requests.get(url, headers=self.headers) as response:
            return response

    def create_property_category(self, name: str, language: str) -> requests.Response:
        """
        Creates a new property category using the parameters.
        Input: name: str, language: str.
        Output: requests.Response.
        """

        if language and len(language) != 2:
            raise SyntaxError('Language must be 2 characters.')

        payload = {
            'name': name,
            'lang': language
        }

        url = self.get_url('properties-categories')
        with requests.post(url, headers=self.headers, data=payload) as response:
            return response

    def gen_payload(self, object_payload: dict, name: str, language: str, description: str = None, main_image: str = None, parent_id: int = None, children: list = [], aliases: list = [], images: list = [], properties: list = [], links: list = []) -> dict:
        payload = object_payload
        if name:
            payload['name'] = name

        if language:
            payload['lang'] = language

        if description:
            payload['description'] = description
        
        if parent_id:
            payload['parents[][Objects][id]'] = str(parent_id)

        for index in range(len(children)):
            payload[f'children[{index}][Objects][id]'] = str(children[index])

        for index in range(len(aliases)):
            payload[f'aliases[{index}]'] = aliases[index]

        files = []
        for i in range(len(images)):
            image_type = 'image/png' if '.png' in images[i] else 'image/jpeg'
            files.append((f'Objects[imageFiles][{i}]', (images[i], open(images[i], 'rb'), image_type)))

        if main_image:
            main_image_checksum = [md5(open(x, 'rb').read()).hexdigest() for x in images if x == main_image]
            if main_image_checksum:
                payload['main_image'] = main_image_checksum[0]
            else:
                raise NameError('The main_image file you provided isn\'t exist.')

        for _property in properties:
            payload[f'objectsPropertiesValues[{_property["id"]}][ObjectsPropertiesValues][property_id]'] = _property['id']
            payload[f'objectsPropertiesValues[{_property["id"]}][ObjectsPropertiesValues][type]'] = _property['type']

            for key in _property.keys():
                if key in ['id', 'type']:
                    continue

                if key not in self.valid_property_settings:
                    raise KeyError(f'The key "{key}" of the property is invalid.')

                if type(_property[key]) == list and key == 'value':
                    for index, value in enumerate(_property[key]):
                        try:
                            value = value.strip()
                        except:
                            pass

                        payload[f'objectsPropertiesValues[{_property["id"]}][ObjectsPropertiesValues][{key}][{index}]'] = value
                else:
                    try:
                        _property[key] = _property[key].strip()
                    except:
                        pass

                    payload[f'objectsPropertiesValues[{_property["id"]}][ObjectsPropertiesValues][{key}]'] = _property[key]

        for link in links:
            payload[f'Links[{link["property"]}][url]'] = link['url']

        return {
            'payload': payload,
            'files': files
        }

    def get_url(self, endpoint: str) -> str:
        return f'https://{self.token}:@{API_BASE_URL}/{endpoint}'
