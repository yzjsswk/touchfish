from enum import Enum
from yfunc import *

class TopicType(Enum):
    Info = 'Info'
    Warning = 'Warning'
    Error = 'Error'

class TopicExtraInfo:
    
    def __init__(self):
        pass

class MessageLevel(Enum):
    Info = 'Info'
    Warning = 'Warning'
    Error = 'Error'

class MessageExtraInfo:
    
    def __init__(self):
        pass