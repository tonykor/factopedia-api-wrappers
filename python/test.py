import factopedia

def main() -> None:
    api = factopedia.Factopedia('YOUR_API_KEY')

    # print('Get an object by id 100 expand=["parents", "propertirs"]')
    # response = api.get_object_by_id(100, expand=['parents', 'properties'])
    # print('Response:', response, response.json(), '\n')

    # print('Get an object by filter [name="Cars"]')
    # response = api.get_object(name='Cars', expand=['parents', 'children'])
    # print('Response:', response, response.json(), '\n')

    print('Creating a new object named "test" [lang="en", parent_id=42102, description="Lorem ipsum ut in in minim est reprehenderit excepteur eiusmod proident esse.", images=["map.png", "moon.jpg"], main_image="map.png", proporties=[{\'id\': 151, \'type\': \'text\', \'value\': \'Just a test\'}], aliases=["helloman", "hellowoman"]')
    f_response = api.create_object('Excepteur dolor', 'en', parent_id=42102, description='Lorem ipsum ut in in minim est reprehenderit excepteur eiusmod proident esse.', images=['map.png', 'moon.jpg'], main_image='moon.jpg', properties=[{'id': 151, 'type': 'text', 'value': 'Just a test'}, {'id': 154, 'type': 'int', 'value': '125', 'unit_id': 8, 'order_by': 2, 'category_id':8}], aliases=['lorem', 'ipsum', 'sit'], links=[{'property': 154, 'url': 'https://factopedia.org'}, {'property': 151, 'url': 'https://api.factopedia.org'}])
    print('Response:', f_response, f_response.json(), '\n')

    print('Get an object by filter [name="Chemistry"]')
    response = api.get_object(name='Mobile phones', expand=['parents', 'properties'])
    print('Response:', response, response.json(), '\n')

    print('Get a property by filter [name="Technology", lang="en"]')
    response = api.get_property('Technology', 'en')
    print('Response:', response, response.json(), '\n')

    print('Get an object by id 100')
    response = api.get_object_by_id(100)
    print('Response:', response, response.json(), '\n')

    print(f'Update the first response page by his id [{f_response.json()["id"]}]')
    response = api.update_object(f_response.json()['id'], name='Rhino testing')
    print('Response:', response, response.json(), '\n')

    print('Create a new property name="Technology", lang="en", type="text"')
    response = api.create_property(name='Technology', language='en', property_type='text')
    print('Response:', response, response.json())

if __name__ == '__main__':
    main()
