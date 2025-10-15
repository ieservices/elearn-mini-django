import responses
from courses.integrations.sf_client import SuccessFactorsClient

@responses.activate
def test_sf_client_get_user():
    base = "https://example.successfactors.com"
    client = SuccessFactorsClient(base_url=base, token="x")
    responses.add(
        responses.GET,
        f"{base}/odata/v2/User('123')",
        json={"d": {"userId": "123", "firstName": "Ada"}},
        status=200,
    )
    data = client.get_user("123")
    assert data["userId"] == "123"
    assert data["firstName"] == "Ada"
