
with open('lib/features/profile/presentation/screens/accepted_payment_page.dart', 'r') as f:
    content = f.read()
    balance = 0
    for i, char in enumerate(content):
        if char == '{':
            balance += 1
        elif char == '}':
            balance -= 1
        if balance < 0:
            print(f"Brace underflow at character {i}")
            break
    print(f"Final balance: {balance}")
