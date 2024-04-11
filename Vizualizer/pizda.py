import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
# Константы
G = 9.81 # Ускорение свободного падения (м/с^2)
NUM_PARTICLES = 100 # Количество молекул
MAX_VELOCITY = 10 # Максимальная начальная скорость молекул (м/с)
DT = 0.1 # Временной шаг для численного интегрирования (сек)
BOX_SIZE = 10 # Размеры коробки (м)
# Генерация начальных условий для молекул
positions = np.random.rand(NUM_PARTICLES, 2) * BOX_SIZE # Случайные начальные позиции (x, y)
velocities = (np.random.rand(NUM_PARTICLES, 2) - 0.5) * 2 * MAX_VELOCITY # Случайные начальные скорости (vx, vy)
# Функция для обновления положения молекул
def update_positions():
    global positions, velocities
    # Применение силы тяжести к скоростям
    velocities[:, 1] -= G * DT
    # Обновление положения на основе скорости
    positions += velocities * DT
    # Обработка столкновений с границами коробки
    if positions < 0:

    else if positions > BOX_S
    positions[positions < 0] = 0
    positions[positions > BOX_SIZE] = BOX_SIZE
    # Обработка столкновений с полом коробки (просто обратить скорость по y)
    velocities[positions[:, 1] == 0, 1] *= -1
    velocities[positions[:, 1] == BOX_SIZE, 1] *= -1
    velocities[positions[:, 0] == 0, 0] *= -1
    velocities[positions[:, 0] == BOX_SIZE, 0] *= -1

# Функция инициализации анимации
def init():
    global scat
    scat = ax.scatter([], [])
    return scat,
# Функция для обновления анимации
def animate(frame):
    update_positions()
    scat.set_offsets(positions)
    return scat,
# Создание окна для анимации
fig, ax = plt.subplots()
ax.set_xlim(0, BOX_SIZE)
ax.set_ylim(0, BOX_SIZE)
ax.set_aspect('equal')
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_title('Моделирование идеального газа под воздействием силы тяжести')
# Запуск анимации
ani = FuncAnimation(fig, animate, frames=1000, init_func=init, blit=True, interval=50)
plt.show()