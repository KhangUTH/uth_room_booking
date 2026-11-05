class Room {
  final String name;
  final String status;
  const Room(this.name, this.status);
}

class Device {
  final String name;
  final String status;
  const Device(this.name, this.status);
}

const sampleRooms = [
  Room('Phòng A101', 'Trống'),
  Room('Phòng A102', 'Đang sử dụng'),
  Room('Phòng B201', 'Trống'),
  Room('Phòng B202', 'Bảo trì'),
  Room('Phòng C301', 'Trống'),
];

const sampleDevices = [
  Device('Máy chiếu Epson', 'Sẵn sàng'),
  Device('Micro không dây', 'Đang mượn'),
  Device('Laptop Dell', 'Sẵn sàng'),
  Device('Loa Bluetooth', 'Hỏng'),
  Device('Bảng tương tác', 'Sẵn sàng'),
];