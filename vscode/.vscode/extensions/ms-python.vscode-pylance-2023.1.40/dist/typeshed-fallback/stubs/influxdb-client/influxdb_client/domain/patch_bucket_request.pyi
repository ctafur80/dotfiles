from _typeshed import Incomplete

class PatchBucketRequest:
    openapi_types: Incomplete
    attribute_map: Incomplete
    discriminator: Incomplete
    def __init__(
        self, name: Incomplete | None = ..., description: Incomplete | None = ..., retention_rules: Incomplete | None = ...
    ) -> None: ...
    @property
    def name(self): ...
    @name.setter
    def name(self, name) -> None: ...
    @property
    def description(self): ...
    @description.setter
    def description(self, description) -> None: ...
    @property
    def retention_rules(self): ...
    @retention_rules.setter
    def retention_rules(self, retention_rules) -> None: ...
    def to_dict(self): ...
    def to_str(self): ...
    def __eq__(self, other): ...
    def __ne__(self, other): ...
