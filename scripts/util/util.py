from datetime import date

DATE_FORMAT = "%Y-%m-%d"


def version_to_date(version) -> date:
    return date(
        year=int(version["year"]),
        month=int(version["month"]),
        day=int(version["day"]),
    )
