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

        self.valid_property_settings = ['category_id', 'unit_id', 'value', 'order_by']
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

        payload = {
            'name': name,
            'lang': language
        }

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
                    payload[f'Objects[objectsPropertiesValues][{_property["id"]}][ObjectsPropertiesValues][{key}][]'] = _property[key][0]
                else:
                    payload[f'objectsPropertiesValues[{_property["id"]}][ObjectsPropertiesValues][{key}]'] = _property[key]

        for link in links:
            payload[f'Links[{link["property"]}][url]'] = link['url']

        url = self.get_url('objects')
        with requests.post(url, headers=self.headers, data=payload, files=files) as response:
            return response

    def update_object(self, object_id: int, aliases: list = [], links: list = [], **kwargs) -> requests.Response:
        """
        Updates an object by his id. Updated fields are the kwargs.
        Input: object_id: int, aliases: list = [], **kwargs.
        Output: requests.Response.
        """

        if not kwargs and not links and not aliases:
            raise ValueError(f'You didn\'t provide any changes to object id {object_id}.')

        object_payload = self.get_object_by_id(object_id, expand=['properties']).json()
        # object_payload['aliases'] += aliases
        print(object_payload)

        for link in links:
            _property = str(link['property'])
            if _property in object_payload['properties']:
                object_payload['properties'][_property]['link'] = link['url']

            payload = {f'Links[{link["property"]}][url]': link['url']}

        for key in kwargs.keys():
            if key in self.update_values:
                key = self.update_values[key]

            object_payload[key] = kwargs[key]

        url = self.get_url(f'objects/{object_id}')
        with requests.put(url, headers=self.headers, data=payload) as response:
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

    def get_url(self, endpoint: str) -> str:
        return f'https://{self.token}:@{API_BASE_URL}/{endpoint}'
