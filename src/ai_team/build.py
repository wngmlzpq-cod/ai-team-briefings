from .site_generator import SiteGenerator


def main() -> None:
    print("=== AI Team Portal Build Start ===")
    generator = SiteGenerator()
    total = generator.build()
    print("=== AI Team Portal Build Complete ===")
    print(f"Converted reports: {total}")
    print("Portal: docs/index.html")


if __name__ == "__main__":
    main()
