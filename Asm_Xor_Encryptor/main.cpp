#include <iostream>
#include <string>
#include <vector>
#include <limits>
#include <cstdlib>
#include <windows.h>

#ifdef max
#undef max
#endif

extern "C" void XOREncrypt(unsigned char* buffer, unsigned int bufSize, unsigned char* key, unsigned int keySize);
extern "C" void BytesToHex(unsigned char* buffer, unsigned int bufSize, char* hexBuffer);

// Функция для преобразования hex-строки в массив байтов
std::vector<unsigned char> HexToBytes(const std::string& hex) {
    std::vector<unsigned char> bytes;
    for (size_t i = 0; i < hex.length(); i += 2) {
        std::string byteString = hex.substr(i, 2);
        unsigned char byte = static_cast<unsigned char>(std::stoi(byteString, nullptr, 16));
        bytes.push_back(byte);
    }
    return bytes;
}

// Функция для проверки, является ли строка валидной hex-строкой
bool IsValidHex(const std::string& hex) {
    if (hex.empty() || hex.length() % 2 != 0) {
        return false; // Длина должна быть четной
    }
    for (char c : hex) {
        if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
            return false; // Допустимы только символы 0-9, A-F, a-f
        }
    }
    return true;
}

// Функция для копирования текста в буфер обмена (Windows)
void SetClipboardText(const std::string& text) {
    if (OpenClipboard(NULL)) {
        EmptyClipboard();
        HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, text.size() + 1);
        if (hMem) {
            memcpy(GlobalLock(hMem), text.c_str(), text.size() + 1);
            GlobalUnlock(hMem);
            SetClipboardData(CF_TEXT, hMem);
        }
        CloseClipboard();
    }
}

int main() {
    // Установка кодировки консоли на UTF-8
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    // Установка локали для корректного отображения русских символов
    setlocale(LC_ALL, "Russian");

    while (true) {
        system("cls");
        std::string mode;
        std::cout << "Введите режим (enc - шифрование, dec - дешифрование, или exit для выхода): ";
        std::getline(std::cin, mode);
        if (mode == "exit") {
            break;
        }

        if (mode == "enc") {
            std::string text;
            std::cout << "Введите строку для шифрования (1-256 символов): ";
            std::getline(std::cin, text);
            if (text.empty() || text.length() > 256) {
                std::cout << "Ошибка: строка должна содержать от 1 до 256 символов." << std::endl;
                std::cout << "Нажмите Enter для продолжения...";
                std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
                continue;
            }

            std::string key;
            std::cout << "Введите ключ (1-256 символов): ";
            std::getline(std::cin, key);
            if (key.empty() || key.length() > 256) {
                std::cout << "Ошибка: ключ должен содержать от 1 до 256 символов." << std::endl;
                std::cout << "Нажмите Enter для продолжения...";
                std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
                continue;
            }

            std::vector<unsigned char> textVec(text.begin(), text.end());
            textVec.push_back('\0');
            std::vector<unsigned char> keyVec(key.begin(), key.end());
            keyVec.push_back('\0');

            size_t textSize = textVec.size() - 1;
            size_t keySize = keyVec.size() - 1;

            XOREncrypt(textVec.data(), static_cast<unsigned int>(textSize), keyVec.data(), static_cast<unsigned int>(keySize));

            // Используем std::vector для безопасного выделения памяти
            std::vector<char> hexText(textSize * 2 + 1);
            BytesToHex(textVec.data(), static_cast<unsigned int>(textSize), hexText.data());
            std::string hexString(hexText.data());

            SetClipboardText(hexString);
            std::cout << "Зашифровано (hex): " << hexString << std::endl;
            std::cout << "Результат в hex-формате скопирован в буфер обмена." << std::endl;
        }
        else if (mode == "dec") {
            std::string hexText;
            std::cout << "Введите зашифрованную строку в hex-формате (длина должна быть четной, 2-512 символов): ";
            std::getline(std::cin, hexText);
            if (hexText.empty() || hexText.length() < 2 || hexText.length() > 512 || !IsValidHex(hexText)) {
                std::cout << "Ошибка: строка должна быть валидной hex-строкой (2-512 символов, только 0-9, A-F, a-f)." << std::endl;
                std::cout << "Нажмите Enter для продолжения...";
                std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
                continue;
            }

            std::string key;
            std::cout << "Введите ключ (1-256 символов): ";
            std::getline(std::cin, key);
            if (key.empty() || key.length() > 256) {
                std::cout << "Ошибка: ключ должен содержать от 1 до 256 символов." << std::endl;
                std::cout << "Нажмите Enter для продолжения...";
                std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
                continue;
            }

            std::vector<unsigned char> textVec = HexToBytes(hexText);
            textVec.push_back('\0');
            std::vector<unsigned char> keyVec(key.begin(), key.end());
            keyVec.push_back('\0');

            size_t textSize = textVec.size() - 1;
            size_t keySize = keyVec.size() - 1;

            XOREncrypt(textVec.data(), static_cast<unsigned int>(textSize), keyVec.data(), static_cast<unsigned int>(keySize));
            std::string decryptedText(reinterpret_cast<char*>(textVec.data()), textSize);
            SetClipboardText(decryptedText);
            std::cout << "Расшифровано: " << decryptedText << std::endl;
            std::cout << "Результат скопирован в буфер обмена." << std::endl;
        }
        else {
            std::cout << "Неверный режим." << std::endl;
        }

        std::cout << "Нажмите Enter для продолжения...";
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }
    return 0;
}