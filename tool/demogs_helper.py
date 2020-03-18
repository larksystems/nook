# A Python library to help process demogs

def try_parse_age(age):
    try:
        return int(age)
    except ValueError:
        return None

def age_range(age):
    int_age = try_parse_age(age)
    if int_age == None:
        return "unknown"
    if int_age < 18:
        return "0_18"
    if int_age < 35:
        return "18_35"
    if int_age < 50:
        return "35_50"
    return "50+"

gender_options = ["male", "female", "unknown"]
age_ranges = ["0_18", "18_35", "35_50", "50+", "unknown"]
