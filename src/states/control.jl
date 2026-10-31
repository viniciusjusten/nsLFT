# The states of the controls of an element, such as the governor and the voltage regulator of a generator, or the
# frequency estimation of a bus, are kept inside the state of that element, so the results are written with the
# element they belong to
abstract type ControlState end
