$script:FIXICS_RptErrorPatterns = @(
    'Error in expression',
    'Error position',
    'Error Generic error',
    'Undefined variable',
    'Type \w+, expected',
    'Script.*not found',
    'Cannot load mission',
    '0 elements provided',
    'File.*line \d+'
)

$script:FIXICS_RptProjectPatterns = @(
    '\[FIXICS',
    'FIXICS_fnc_',
    'FIXICS_'
)

$script:FIXICS_RptPhysicsPatterns = @(
    'PhysicsCollision',
    'disableBrakes',
    'setVelocity',
    'velocityModelSpace',
    'setVelocityModelSpace',
    'angularVelocity',
    'addForce',
    'addTorque'
)

$script:FIXICS_RptWarningPatterns = @(
    'Warning',
    'warning',
    'cannot find'
)
